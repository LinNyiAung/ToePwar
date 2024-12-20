from fastapi import APIRouter, HTTPException, Depends
from database import transactions_collection, goals_collection
from models.transaction_model import Transaction
from bson import ObjectId
from utils import get_current_user
from datetime import datetime
from utils import serialize_transaction
from routes.dashboard_routes import get_dashboard

from bson.errors import InvalidId

router = APIRouter()

@router.post("/addtransactions")
def add_transaction(transaction: Transaction, user_id: str = Depends(get_current_user)):
    print("Received transaction:", transaction.dict())
    transaction_data = transaction.dict()
    transaction_data["user_id"] = user_id
    result = transactions_collection.insert_one(transaction_data)

    # Update goals based on the transaction type
    if transaction.type == "income":
        update_goals_for_income(user_id, transaction.amount)
    elif transaction.type == "expense":
        update_goals_for_expense(user_id, transaction.amount)

    # Return the created transaction
    created_transaction = transactions_collection.find_one({"_id": result.inserted_id})
    return serialize_transaction(created_transaction)


def update_goals_for_income(user_id: str, amount: float):
    remaining_balance = amount
    
    goals = goals_collection.find({
        "user_id": user_id,
        "completed": {"$ne": True}
    }).sort("deadline", 1)

    for goal in goals:
        target_amount = goal["target_amount"]
        current_amount = goal["current_amount"]
        needed_amount = target_amount - current_amount

        if remaining_balance >= needed_amount:
            goals_collection.update_one(
                {"_id": goal["_id"]},
                {
                    "$set": {
                        "current_amount": target_amount,
                        "completed": True,
                        "completion_date": datetime.utcnow()
                    }
                }
            )
            remaining_balance -= needed_amount
        elif remaining_balance > 0:
            new_amount = current_amount + remaining_balance
            goals_collection.update_one(
                {"_id": goal["_id"]},
                {"$set": {"current_amount": new_amount}}
            )
            break


def update_goals_for_expense(user_id: str, amount: float):
    remaining_decrement = amount

    goals = goals_collection.find({
        "user_id": user_id,
        "completed": {"$ne": True}
    }).sort("deadline", -1)  # Start with the least priority goal

    for goal in goals:
        current_amount = goal["current_amount"]

        if current_amount >= remaining_decrement:
            goals_collection.update_one(
                {"_id": goal["_id"]},
                {"$set": {"current_amount": current_amount - remaining_decrement}}
            )
            break
        else:
            goals_collection.update_one(
                {"_id": goal["_id"]},
                {"$set": {"current_amount": 0}}
            )
            remaining_decrement -= current_amount

def update_goals_from_balance(user_id: str):
    # Get current balance
    dashboard = get_dashboard(user_id)
    current_balance = dashboard["balance"]
    
    # Get all active goals
    goals = goals_collection.find({
        "user_id": user_id,
        "completed": {"$ne": True}  # Only get uncompleted goals
    }).sort("deadline", 1)  # Sort by deadline ascending
    
    remaining_balance = current_balance
    
    for goal in goals:
        target_amount = goal["target_amount"]
        current_amount = goal["current_amount"]
        needed_amount = target_amount - current_amount
        
        if remaining_balance >= needed_amount:
            # Complete this goal
            goals_collection.update_one(
                {"_id": goal["_id"]},
                {
                    "$set": {
                        "current_amount": target_amount,
                        "completed": True,
                        "completion_date": datetime.utcnow()
                    }
                }
            )
            remaining_balance -= needed_amount
        elif remaining_balance > 0:
            # Partially fund this goal
            new_amount = current_amount + remaining_balance
            goals_collection.update_one(
                {"_id": goal["_id"]},
                {"$set": {"current_amount": new_amount}}
            )
            remaining_balance = 0
        
        if remaining_balance <= 0:
            break


@router.put("/edittransactions/{transaction_id}")
def update_transaction(
    transaction_id: str,
    transaction: Transaction,
    user_id: str = Depends(get_current_user)
):
    print(f"Received PUT request for transaction ID: {transaction_id}")
    print(f"Transaction data: {transaction.dict()}")
    print(f"User ID: {user_id}")
    
    try:
        # Convert string ID to ObjectId
        transaction_object_id = ObjectId(transaction_id)
        
        # Verify the transaction exists and belongs to the user
        existing_transaction = transactions_collection.find_one({
            "_id": transaction_object_id,
            "user_id": user_id
        })
        
        if not existing_transaction:
            raise HTTPException(
                status_code=404, 
                detail=f"Transaction {transaction_id} not found for user {user_id}"
            )
        
        # Update the transaction
        update_data = transaction.dict()
        update_data["user_id"] = user_id
        
        result = transactions_collection.update_one(
            {"_id": transaction_object_id, "user_id": user_id},
            {"$set": update_data}
        )
        
        if result.modified_count == 0:
            raise HTTPException(
                status_code=400, 
                detail="Transaction update failed - no modifications made"
            )
        
        # Return the updated transaction
        updated_transaction = transactions_collection.find_one({"_id": transaction_object_id})
        return serialize_transaction(updated_transaction)
        
    except InvalidId:
        raise HTTPException(
            status_code=400, 
            detail=f"Invalid transaction ID format: {transaction_id}"
        )
    except Exception as e:
        print(f"Error updating transaction: {str(e)}")
        raise HTTPException(
            status_code=500, 
            detail=f"Failed to update transaction: {str(e)}"
        )


# Get Transaction History
@router.get("/gettransactions")
def get_transaction_history(user_id: str = Depends(get_current_user)):
    transactions = transactions_collection.find({"user_id": user_id}).sort("date", -1)  # Sort by date, latest first
    serialized_transactions = [serialize_transaction(txn) for txn in transactions]  # Serialize each transaction
    return serialized_transactions


@router.delete("/deletetransactions/{transaction_id}")
def delete_transaction(transaction_id: str, user_id: str = Depends(get_current_user)):
    try:
        transaction_object_id = ObjectId(transaction_id)
        
        # Get transaction type before deletion
        transaction = transactions_collection.find_one({
            "_id": transaction_object_id,
            "user_id": user_id
        })
        
        if not transaction:
            raise HTTPException(
                status_code=404, 
                detail=f"Transaction {transaction_id} not found for user {user_id}"
            )
        
        # Delete the transaction
        result = transactions_collection.delete_one({
            "_id": transaction_object_id,
            "user_id": user_id
        })
        
        # Update goals after deletion
        if transaction["type"] == "income":
            update_goals_from_balance(user_id)
        
        return {"message": "Transaction deleted successfully"}
        
    except InvalidId:
        raise HTTPException(
            status_code=400, 
            detail=f"Invalid transaction ID format: {transaction_id}"
        )
    except Exception as e:
        print(f"Error deleting transaction: {str(e)}")
        raise HTTPException(
            status_code=500, 
            detail=f"Failed to delete transaction: {str(e)}"
        )
    