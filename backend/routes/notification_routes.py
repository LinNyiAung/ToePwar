from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException
from database import transactions_collection, notifications_collection
from utils import get_current_user
from datetime import datetime, timedelta
from typing import List
import statistics

router = APIRouter()

def detect_unusual_expense(user_id: str, transaction: dict):
    """
    Detect if an expense is unusually large compared to recent spending patterns
    """
    # Check expenses in the last 30 days
    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    recent_expenses = list(transactions_collection.find({
        "user_id": user_id,
        "type": "expense",
        "date": {"$gte": thirty_days_ago}
    }))

    if len(recent_expenses) < 5:
        # Not enough data to determine unusual spending
        return False

    # Calculate mean and standard deviation of recent expenses
    expense_amounts = [expense['amount'] for expense in recent_expenses]
    mean_expense = statistics.mean(expense_amounts)
    std_dev = statistics.stdev(expense_amounts)

    # Define unusual expense as more than 2 standard deviations above mean
    is_unusual = transaction['amount'] > (mean_expense + 2 * std_dev)

    return is_unusual

def create_expense_alert_notification(user_id: str, transaction: dict):
    """
    Create both in-app and system notifications for an unusual expense
    """
    notification = {
        "user_id": user_id,
        "title": "Unusual Expense Alert",
        "message": f"Large {transaction['category']} expense of K{transaction['amount']:.2f} detected",
        "timestamp": datetime.utcnow(),
        "type": "expenseAlert",
        "isRead": False,
        "requiresSystemNotification": True  # Add this flag
    }
    result = notifications_collection.insert_one(notification)
    return str(result.inserted_id)


@router.get("/getnotifications")
def get_notifications(user_id: str = Depends(get_current_user)):
    notifications = list(notifications_collection.find({"user_id": user_id}).sort("timestamp", -1))
    
    # Convert ObjectId to string
    for notification in notifications:
        notification['id'] = str(notification['_id'])
        del notification['_id']
    
    return notifications

@router.put("/marknotification/{notification_id}")
def mark_notification_as_read(notification_id: str, user_id: str = Depends(get_current_user)):
    try:
        result = notifications_collection.update_one(
            {"_id": ObjectId(notification_id), "user_id": user_id},
            {"$set": {"isRead": True}}
        )
        
        if result.modified_count == 0:
            raise HTTPException(status_code=404, detail="Notification not found")
        
        return {"message": "Notification marked as read"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error marking notification: {str(e)}")


@router.delete("/deletenotification/{notification_id}")
def delete_notification(notification_id: str, user_id: str = Depends(get_current_user)):
    try:
        result = notifications_collection.delete_one(
            {"_id": ObjectId(notification_id), "user_id": user_id}
        )
        
        if result.deleted_count == 0:
            raise HTTPException(status_code=404, detail="Notification not found")
        
        return {"message": "Notification deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error deleting notification: {str(e)}")