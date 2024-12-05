from fastapi import FastAPI, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from datetime import datetime
from database import users_collection, transactions_collection, goals_collection
from auth import hash_password, verify_password, create_access_token, SECRET_KEY, ALGORITHM
from schemas import UserSignUp, UserLogin, Token
from models import Transaction, Goal
from bson import ObjectId

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

# Add Transaction
@app.post("/transaction")
def add_transaction(transaction: Transaction, user_id: str = Depends(get_current_user)):
    print("Received transaction:", transaction.dict())  # Debugging log

    transaction_data = transaction.dict()
    transaction_data["user_id"] = user_id  # Add user_id to the transaction
    transactions_collection.insert_one(transaction_data)
    return {"message": "Transaction added"}


# Get Transaction History
@app.get("/transactions")
def get_transaction_history(user_id: str = Depends(get_current_user)):
    transactions = transactions_collection.find({"user_id": user_id}).sort("date", -1)  # Sort by date, latest first
    serialized_transactions = [serialize_transaction(txn) for txn in transactions]  # Serialize each transaction
    return serialized_transactions


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
    return {"income": next(income, {}).get("total_income", 0), 
            "expense": next(expense, {}).get("total_expense", 0)}

# Set Saving Goal
@app.post("/goal")
def set_goal(goal: Goal, user_id: str = Depends(get_current_user)):
    goal_data = goal.dict()
    goal_data["user_id"] = user_id
    goals_collection.insert_one(goal_data)
    return {"message": "Goal set successfully"}

# Fetch Goals
@app.get("/goals")
def get_goals(user_id: str = Depends(get_current_user)):
    goals = goals_collection.find({"user_id": user_id})
    return {"goals": list(goals)}
