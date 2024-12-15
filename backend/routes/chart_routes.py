from fastapi import APIRouter, HTTPException, Query, Depends
from database import transactions_collection, goals_collection
from utils import get_current_user
from datetime import datetime, timedelta

router = APIRouter()

@router.get("/expense-categories")
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



@router.get("/income-categories")
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
