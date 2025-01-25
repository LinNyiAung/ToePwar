from fastapi import APIRouter, HTTPException, Depends
from database import transactions_collection, goals_collection
from models.transaction_model import Transaction
from bson import ObjectId
from routes.notification_routes import create_expense_alert_notification, detect_unusual_expense
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
        transaction_data = transaction.dict()
        transaction_data["user_id"] = user_id

        if detect_unusual_expense(user_id, transaction_data):
            create_expense_alert_notification(user_id, transaction_data)

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
    }).sort("deadline", -1)

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


def revert_transaction_impact(transaction: dict):
    """Reverse the impact of a transaction on goals before updating/deleting it"""
    if transaction["type"] == "income":
        # For income, we need to decrease goal amounts
        update_goals_for_expense(transaction["user_id"], transaction["amount"])
    else:
        # For expense, we need to increase goal amounts
        update_goals_for_income(transaction["user_id"], transaction["amount"])

def apply_new_transaction_impact(transaction_data: dict):
    """Apply the impact of a new or updated transaction on goals"""
    if transaction_data["type"] == "income":
        update_goals_for_income(transaction_data["user_id"], transaction_data["amount"])
    else:
        update_goals_for_expense(transaction_data["user_id"], transaction_data["amount"])


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
    try:
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
        
        # First, revert the impact of the old transaction
        revert_transaction_impact(existing_transaction)
        
        # Update the transaction
        update_data = transaction.dict()
        update_data["user_id"] = user_id
        
        result = transactions_collection.update_one(
            {"_id": transaction_object_id, "user_id": user_id},
            {"$set": update_data}
        )
        
        if result.modified_count == 0:
            # If update failed, reapply old transaction impact
            apply_new_transaction_impact(existing_transaction)
            raise HTTPException(
                status_code=400,
                detail="Transaction update failed - no modifications made"
            )
        
        # Apply the impact of the new transaction
        apply_new_transaction_impact(update_data)
        
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
        
        # Get transaction before deletion
        transaction = transactions_collection.find_one({
            "_id": transaction_object_id,
            "user_id": user_id
        })
        
        if not transaction:
            raise HTTPException(
                status_code=404,
                detail=f"Transaction {transaction_id} not found for user {user_id}"
            )
        
        # Revert the impact of the transaction before deletion
        revert_transaction_impact(transaction)
        
        # Delete the transaction
        result = transactions_collection.delete_one({
            "_id": transaction_object_id,
            "user_id": user_id
        })
        
        if result.deleted_count == 0:
            # If deletion failed, reapply transaction impact
            apply_new_transaction_impact(transaction)
            raise HTTPException(
                status_code=400,
                detail="Transaction deletion failed"
            )
        
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
    