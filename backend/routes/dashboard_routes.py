from fastapi import APIRouter, Depends
from database import transactions_collection
from utils import get_current_user


router = APIRouter()

@router.get("/dashboard")
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
