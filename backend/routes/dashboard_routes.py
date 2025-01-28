from bson import ObjectId
from fastapi import APIRouter, Depends
from database import transactions_collection, notifications_collection
from routes.notification_routes import check_low_balance, create_balance_alert_notification
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

    # Check for low balance and create notification if needed
    if check_low_balance(user_id, balance):
        notification_id = create_balance_alert_notification(user_id, balance)
        notification = notifications_collection.find_one({"_id": ObjectId(notification_id)})
        if notification:
            notification['id'] = str(notification['_id'])
            del notification['_id']
            return {
                "income": total_income,
                "expense": total_expense,
                "balance": balance,
                "notification": notification
            }

    return {
        "income": total_income,
        "expense": total_expense,
        "balance": balance
    }
