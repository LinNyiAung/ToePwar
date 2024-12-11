from fastapi import FastAPI, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from datetime import datetime
from database import users_collection, transactions_collection, goals_collection
from auth import hash_password, verify_password, create_access_token, SECRET_KEY, ALGORITHM
from schemas import UserSignUp, UserLogin, Token
from models import Transaction, Goal
from bson import ObjectId
from bson.errors import InvalidId

app = FastAPI()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

# Helper function to get current user
def get_current_user(token: str = Depends(oauth2_scheme)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid credentials")
        return user_id
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    

# Helper function to serialize MongoDB documents
def serialize_transaction(transaction):
    transaction["_id"] = str(transaction["_id"])  # Convert ObjectId to string
    transaction["user_id"] = str(transaction["user_id"])  # Convert user_id ObjectId to string if needed
    return transaction

# User Registration
@app.post("/register")
def register(user: UserSignUp):
    if users_collection.find_one({"email": user.email}):
        raise HTTPException(status_code=400, detail="Email already registered")
    if users_collection.find_one({"username": user.username}):
        raise HTTPException(status_code=400, detail="Username already taken")
    hashed_password = hash_password(user.password)
    users_collection.insert_one({
        "username": user.username,
        "email": user.email,
        "password": hashed_password
    })
    return {"message": "User registered successfully"}

# User Login
@app.post("/login", response_model=Token)
def login(user: UserLogin):
    db_user = users_collection.find_one({"email": user.email})
    if not db_user or not verify_password(user.password, db_user["password"]):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    token = create_access_token({"sub": str(db_user["_id"])})
    return {"access_token": token, "token_type": "bearer"}


@app.get("/profile")
def get_profile(user_id: str = Depends(get_current_user)):
    # Fetch the user's data from the database using the user_id
    user_data = users_collection.find_one({"_id": ObjectId(user_id)})
    
    if not user_data:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Return the user data, excluding sensitive information like password
    return {
        "id": str(user_data["_id"]),
        "username": user_data["username"],
        "email": user_data["email"]
    }


# Add Transaction
@app.post("/addtransactions")
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


@app.put("/edittransactions/{transaction_id}")
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
@app.get("/gettransactions")
def get_transaction_history(user_id: str = Depends(get_current_user)):
    transactions = transactions_collection.find({"user_id": user_id}).sort("date", -1)  # Sort by date, latest first
    serialized_transactions = [serialize_transaction(txn) for txn in transactions]  # Serialize each transaction
    return serialized_transactions


@app.delete("/deletetransactions/{transaction_id}")
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


# Get Dashboard Summary
@app.get("/dashboard")
def get_dashboard(user_id: str = Depends(get_current_user)):
    income = transactions_collection.aggregate([
        {"$match": {"user_id": user_id, "type": "income"}},
        {"$group": {"_id": None, "total_income": {"$sum": "$amount"}}}
    ])
    expense = transactions_collection.aggregate([
        {"$match": {"user_id": user_id, "type": "expense"}},
        {"$group": {"_id": None, "total_expense": {"$sum": "$amount"}}}
    ])
    
    total_income = next(income, {}).get("total_income", 0)
    total_expense = next(expense, {}).get("total_expense", 0)
    balance = total_income - total_expense
    
    return {
        "income": total_income,
        "expense": total_expense,
        "balance": balance
    }

# Set Saving Goal
@app.post("/goal")
def set_goal(goal: Goal, user_id: str = Depends(get_current_user)):
    goal_data = goal.dict()
    goal_data["user_id"] = user_id
    result = goals_collection.insert_one(goal_data)
    created_goal = goals_collection.find_one({"_id": result.inserted_id})
    created_goal["_id"] = str(created_goal["_id"])
    return created_goal

@app.get("/goals")
def get_goals(user_id: str = Depends(get_current_user)):
    goals = goals_collection.find({"user_id": user_id})
    goals_list = []
    for goal in goals:
        goal["_id"] = str(goal["_id"])
        goals_list.append(goal)
    return {"goals": goals_list}

@app.delete("/deletegoals/{goal_id}")
def delete_goal(goal_id: str, user_id: str = Depends(get_current_user)):
    try:
        goal_object_id = ObjectId(goal_id)
        result = goals_collection.delete_one({
            "_id": goal_object_id,
            "user_id": user_id
        })
        
        if result.deleted_count == 0:
            raise HTTPException(
                status_code=404,
                detail="Goal not found or unauthorized"
            )
            
        return {"message": "Goal deleted successfully"}
        
    except InvalidId:
        raise HTTPException(
            status_code=400,
            detail="Invalid goal ID format"
        )
    


@app.put("/editgoals/{goal_id}")
def update_goal(
    goal_id: str,
    goal: Goal,
    user_id: str = Depends(get_current_user)
):
    try:
        goal_object_id = ObjectId(goal_id)
        
        # Verify the goal exists and belongs to the user
        existing_goal = goals_collection.find_one({
            "_id": goal_object_id,
            "user_id": user_id
        })
        
        if not existing_goal:
            raise HTTPException(
                status_code=404,
                detail="Goal not found or unauthorized"
            )
            
        # Preserve the current_amount and completion status
        update_data = goal.dict()
        update_data["user_id"] = user_id
        update_data["current_amount"] = existing_goal["current_amount"]
        update_data["completed"] = existing_goal["completed"]
        update_data["completion_date"] = existing_goal.get("completion_date")
        
        result = goals_collection.update_one(
            {"_id": goal_object_id, "user_id": user_id},
            {"$set": update_data}
        )
        
        if result.modified_count == 0:
            raise HTTPException(
                status_code=400,
                detail="Goal update failed"
            )
            
        updated_goal = goals_collection.find_one({"_id": goal_object_id})
        updated_goal["_id"] = str(updated_goal["_id"])
        return updated_goal
        
    except InvalidId:
        raise HTTPException(
            status_code=400,
            detail="Invalid goal ID format"
        )
    


@app.get("/expense-categories")
def get_expense_categories(
    user_id: str = Depends(get_current_user),
    start_date: str | None = None,
    end_date: str | None = None
):
    # Base match condition
    match_condition = {
        "user_id": user_id,
        "type": "expense"
    }
    
    # Add date filtering if dates are provided
    if start_date and end_date:
        # Convert strings to datetime objects
        start = datetime.fromisoformat(start_date)
        end = datetime.fromisoformat(end_date)
        
        # Set start time to beginning of day (00:00:00)
        start = datetime(start.year, start.month, start.day, 0, 0, 0)
        
        # Set end time to end of day (23:59:59)
        end = datetime(end.year, end.month, end.day, 23, 59, 59, 999999)
        
        match_condition["date"] = {
            "$gte": start,
            "$lte": end
        }
    
    # Aggregate expenses by category
    pipeline = [
        {
            "$match": match_condition
        },
        {
            "$group": {
                "_id": "$category",
                "total": {"$sum": "$amount"}
            }
        },
        {
            "$project": {
                "category": "$_id",
                "amount": "$total",
                "_id": 0
            }
        }
    ]
    
    categories = list(transactions_collection.aggregate(pipeline))
    return categories



@app.get("/income-categories")
def get_income_categories(
    user_id: str = Depends(get_current_user),
    start_date: str | None = None,
    end_date: str | None = None
):
    # Base match condition
    match_condition = {
        "user_id": user_id,
        "type": "income"
    }
    
    # Add date filtering if dates are provided
    if start_date and end_date:
        # Convert strings to datetime objects
        start = datetime.fromisoformat(start_date)
        end = datetime.fromisoformat(end_date)
        
        # Set start time to beginning of day (00:00:00)
        start = datetime(start.year, start.month, start.day, 0, 0, 0)
        
        # Set end time to end of day (23:59:59)
        end = datetime(end.year, end.month, end.day, 23, 59, 59, 999999)
        
        match_condition["date"] = {
            "$gte": start,
            "$lte": end
        }
    
    # Aggregate incomes by category
    pipeline = [
        {
            "$match": match_condition
        },
        {
            "$group": {
                "_id": "$category",
                "total": {"$sum": "$amount"}
            }
        },
        {
            "$project": {
                "category": "$_id",
                "amount": "$total",
                "_id": 0
            }
        }
    ]
    
    categories = list(transactions_collection.aggregate(pipeline))
    return categories