from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException
import pytz
from database import transactions_collection, notifications_collection, goals_collection
from utils import get_current_user
from datetime import datetime, timedelta
from typing import List
import statistics

router = APIRouter()


def check_goal_reminders(user_id: str):
    """
    Check if any goals need reminders based on progress and deadline
    """
    # Use UTC for all datetime operations
    utc = pytz.UTC
    current_date = datetime.now(utc)
    
    goals = goals_collection.find({
        "user_id": user_id,
        "completed": False
    })
    
    notifications = []
    for goal in goals:
        try:
            # Handle both datetime objects and ISO strings
            if isinstance(goal['deadline'], str):
                # Remove milliseconds if present and handle timezone
                deadline_str = goal['deadline'].split('.')[0]
                if deadline_str.endswith('Z'):
                    deadline_str = deadline_str[:-1] + '+00:00'
                deadline = datetime.fromisoformat(deadline_str)
                if deadline.tzinfo is None:
                    deadline = utc.localize(deadline)
            else:
                deadline = goal['deadline']
                if deadline.tzinfo is None:
                    deadline = utc.localize(deadline)
            
            days_remaining = (deadline - current_date).days
            progress = (goal['current_amount'] / goal['target_amount']) * 100
            
            # Only proceed if days_remaining is positive
            if days_remaining > 0:
                # For calculating total days, handle ObjectId generation time
                start_date = goal['_id'].generation_time.replace(tzinfo=utc)
                total_days = (deadline - start_date).days
                
                if total_days > 0:  # Prevent division by zero
                    time_percentage = ((total_days - days_remaining) / total_days) * 100
                    
                    should_remind = False
                    message = ""
                    
                    if days_remaining <= 7 and progress < 90:
                        should_remind = True
                        message = f"Only {days_remaining} days left to reach your goal '{goal['name']}'. Current progress: {progress:.1f}%"
                    elif days_remaining <= 30 and progress < 50:
                        should_remind = True
                        message = f"{days_remaining} days remaining for goal '{goal['name']}' but only {progress:.1f}% completed"
                    elif progress < time_percentage - 10:
                        should_remind = True
                        message = f"Your goal '{goal['name']}' is behind schedule. Current progress: {progress:.1f}%"
                    
                    if should_remind:
                        notification = {
                            "user_id": user_id,
                            "title": "Goal Reminder",
                            "message": message,
                            "timestamp": current_date,
                            "type": "goalReminder",
                            "isRead": False,
                            "requiresSystemNotification": True
                        }
                        notifications.append(notification)
                        
        except (ValueError, KeyError, TypeError) as e:
            print(f"Error processing goal {goal.get('_id', 'unknown')}: {str(e)}")
            continue
    
    # Insert all notifications
    if notifications:
        notifications_collection.insert_many(notifications)
    
    return [str(notif['_id']) for notif in notifications]

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

    # If no previous expenses, can't determine unusual spending
    if not recent_expenses:
        return False

    # Calculate mean and standard deviation of recent expenses
    expense_amounts = [expense['amount'] for expense in recent_expenses]
    mean_expense = statistics.mean(expense_amounts)
    
    # Handle case with fewer transactions by using a more conservative threshold
    if len(expense_amounts) < 5:
        # For fewer transactions, use a simpler comparison
        # Mark as unusual if more than 3 times the average
        return transaction['amount'] > (mean_expense * 3)
    
    # Calculate standard deviation for more data points
    std_dev = statistics.stdev(expense_amounts)

    # Define unusual expense as more than 2 standard deviations above mean
    # Also check if the expense is significantly larger than the average
    is_unusual = (
        transaction['amount'] > (mean_expense + 2 * std_dev) or 
        transaction['amount'] > (mean_expense * 2.5)
    )

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


def check_low_balance(user_id: str, balance: float) -> bool:
    """
    Check if the user's balance is below the threshold
    Currently set to K1000 as the minimum threshold
    """
    MINIMUM_BALANCE_THRESHOLD = 1000  # You can make this configurable per user
    return balance < MINIMUM_BALANCE_THRESHOLD

def create_balance_alert_notification(user_id: str, balance: float):
    """
    Create both in-app and system notifications for low balance
    """
    notification = {
        "user_id": user_id,
        "title": "Low Balance Alert",
        "message": f"Your current balance is K{balance:.2f}. Consider adding funds to your account.",
        "timestamp": datetime.utcnow(),
        "type": "balanceAlert",
        "isRead": False,
        "requiresSystemNotification": True
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