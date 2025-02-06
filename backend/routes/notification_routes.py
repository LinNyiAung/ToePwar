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
    Returns True if the expense is unusual, False otherwise
    """
    print(f"Starting unusual expense detection for transaction: {transaction}")
    
    try:
        # Only proceed if this is an expense transaction
        if transaction.get('type') != 'expense':
            print("Not an expense transaction, skipping unusual detection")
            return False

        # Get amount from transaction, with validation
        amount = transaction.get('amount')
        if not isinstance(amount, (int, float)) or amount <= 0:
            print(f"Invalid transaction amount: {amount}")
            return False

        # Check expenses in the last 30 days, EXCLUDING the current transaction
        thirty_days_ago = datetime.utcnow() - timedelta(days=30)
        
        # Add query condition to exclude current transaction if it has an _id
        query = {
            "user_id": user_id,
            "type": "expense",
            "date": {"$gte": thirty_days_ago}
        }
        
        # If the transaction has an _id, exclude it from the comparison
        if '_id' in transaction:
            query['_id'] = {'$ne': transaction['_id']}
            
        recent_expenses = list(transactions_collection.find(query))

        print(f"Found {len(recent_expenses)} recent expenses (excluding current)")

        # If this is the first expense or no recent expenses
        if not recent_expenses:
            # For first transaction, flag as unusual if over threshold
            is_unusual = amount > 1000  # Adjust threshold as needed
            print(f"No previous expenses. Amount {amount} > 1000: {is_unusual}")
            return is_unusual

        # Calculate mean of recent expenses
        expense_amounts = [expense['amount'] for expense in recent_expenses]
        mean_expense = statistics.mean(expense_amounts)
        print(f"Mean expense: {mean_expense}")

        # For cases with few transactions (less than 5)
        if len(expense_amounts) < 5:
            # Find the largest previous expense
            max_previous = max(expense_amounts)
            print(f"Few transactions. Max previous expense: {max_previous}")
            
            # Consider unusual if:
            # 1. Amount is more than 2x the largest previous expense, OR
            # 2. Amount is more than 3x the mean expense
            is_unusual = (
                amount > (max_previous * 2) or 
                amount > (mean_expense * 3)
            )
            print(f"Few transactions comparison - Amount: {amount}")
            print(f"Threshold 1 (2x max previous): {max_previous * 2}")
            print(f"Threshold 2 (3x mean): {mean_expense * 3}")
            print(f"Is unusual: {is_unusual}")
            return is_unusual

        # Calculate standard deviation for more data points
        try:
            std_dev = statistics.stdev(expense_amounts)
            print(f"Standard deviation: {std_dev}")
        except statistics.StatisticsError as e:
            print(f"Error calculating standard deviation: {e}")
            # Fallback to simple comparison if std_dev calculation fails
            is_unusual = amount > (mean_expense * 3)
            print(f"Fallback comparison. Amount {amount} > {mean_expense * 3}: {is_unusual}")
            return is_unusual

        # Define unusual expense as more than 2 standard deviations above mean
        # or more than 3x the average
        is_unusual = (
            amount > (mean_expense + 2 * std_dev) or 
            amount > (mean_expense * 3)
        )
        
        print(f"Final unusual check. Amount: {amount}")
        print(f"Threshold 1 (mean + 2*std): {mean_expense + 2 * std_dev}")
        print(f"Threshold 2 (mean * 3): {mean_expense * 3}")
        print(f"Is unusual: {is_unusual}")
        
        return is_unusual

    except Exception as e:
        print(f"Error in detect_unusual_expense: {str(e)}")
        # Return False in case of any errors to avoid false positives
        return False

def create_expense_alert_notification(user_id: str, transaction: dict):
    """
    Create both in-app and system notifications for an unusual expense
    """
    notification = {
        "user_id": user_id,
        "title": "Unusual Expense Alert",
        "message": f"Large {transaction['category']} expense of K{transaction['amount']:.2f} detected",
        "timestamp": datetime.utcnow().isoformat() + 'Z',  # Add 'Z' to indicate UTC
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
        "timestamp": datetime.utcnow().isoformat() + 'Z',  # Add 'Z' to indicate UTC
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