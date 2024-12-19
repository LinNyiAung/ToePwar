from calendar import monthrange
from database import transactions_collection
from datetime import datetime, timedelta
from typing import Dict, List
import statistics

from fastapi import APIRouter, Depends, Query
from models.budget_plan_model import BudgetPlan
from utils import get_current_user

router = APIRouter()

class AIBudgetService:
    def __init__(self, user_id: str):
        self.user_id = user_id

    def generate_budget_plan(self, period_type: str = 'monthly') -> BudgetPlan:
        # Get historical transaction data
        transactions = self._get_historical_transactions(period_type)
        
        # Analyze spending patterns
        spending_patterns = self._analyze_spending_patterns(transactions, period_type)
        
        # Calculate total income and regular expenses based on period
        period_income = self._calculate_period_income(transactions, period_type)
        
        # Generate category-wise budget allocations
        category_budgets = self._generate_category_budgets(
            spending_patterns, 
            period_income,
            period_type
        )
        
        # Generate recommendations
        recommendations = self._generate_recommendations(
            spending_patterns, 
            category_budgets,
            period_type
        )

        # Calculate start and end dates based on period type
        today = datetime.utcnow()
        
        if period_type == 'daily':
            start_date = today
            end_date = start_date + timedelta(days=1)
        elif period_type == 'monthly':
            # Start from first day of current month
            start_date = datetime(today.year, today.month, 1)
            # End on last day of current month
            _, last_day = monthrange(today.year, today.month)
            end_date = datetime(today.year, today.month, last_day, 23, 59, 59)
        else:  # yearly
            # Start from first day of current year
            start_date = datetime(today.year, 1, 1)
            # End on last day of current year
            end_date = datetime(today.year, 12, 31, 23, 59, 59)
        
        return BudgetPlan(
            user_id=self.user_id,
            period_type=period_type,
            start_date=start_date,
            end_date=end_date,
            total_budget=period_income * 0.9,  # Reserve 10% for savings
            category_budgets=category_budgets,
            recommendations=recommendations,
            savings_target=period_income * 0.1
        )

    def _get_historical_transactions(self, period_type: str) -> List[Dict]:
        # Adjust analysis period based on budget period type
        if period_type == 'daily':
            months = 1  # Look at last month for daily patterns
        elif period_type == 'monthly':
            months = 3  # Look at last 3 months
        else:  # yearly
            months = 12  # Look at last year

        start_date = datetime.utcnow() - timedelta(days=30 * months)
        return list(transactions_collection.find({
            "user_id": self.user_id,
            "date": {"$gte": start_date}
        }))
    
    def _calculate_period_income(self, transactions: List[Dict], period_type: str) -> float:
        monthly_income = self._calculate_monthly_income(transactions)
        
        # Convert monthly income to requested period
        if period_type == 'daily':
            return monthly_income / 30
        elif period_type == 'monthly':
            return monthly_income
        else:  # yearly
            return monthly_income * 12

    def _analyze_spending_patterns(self, transactions: List[Dict], period_type: str) -> Dict:
        patterns = {}
        for transaction in transactions:
            if transaction["type"] == "expense":
                category = transaction["category"]
                if category not in patterns:
                    patterns[category] = []
                patterns[category].append(transaction["amount"])
        
        # Calculate statistics for each category
        analysis = {}
        for category, amounts in patterns.items():
            # Adjust statistics based on period type
            divisor = self._get_period_divisor(len(amounts), period_type)
            
            analysis[category] = {
                "average": statistics.mean(amounts) / divisor,
                "median": statistics.median(amounts) / divisor,
                "max": max(amounts),
                "min": min(amounts),
                "total": sum(amounts),
                "frequency": len(amounts)
            }
        return analysis
    
    def _get_period_divisor(self, num_transactions: int, period_type: str) -> float:
        """Helper method to calculate the appropriate divisor for different periods"""
        if period_type == 'daily':
            return 30  # Convert monthly average to daily
        elif period_type == 'monthly':
            return 1  # Keep as monthly
        else:  # yearly
            return 1/12  # Convert monthly to yearly

    def _calculate_monthly_income(self, transactions: List[Dict]) -> float:
        monthly_incomes = []
        current_month = None
        month_total = 0

        for transaction in sorted(transactions, key=lambda x: x["date"]):
            if transaction["type"] == "income":
                transaction_month = transaction["date"].strftime("%Y-%m")
                
                if current_month is None:
                    current_month = transaction_month
                
                if transaction_month != current_month:
                    monthly_incomes.append(month_total)
                    month_total = transaction["amount"]
                    current_month = transaction_month
                else:
                    month_total += transaction["amount"]
        
        if month_total > 0:
            monthly_incomes.append(month_total)
        
        return statistics.mean(monthly_incomes) if monthly_incomes else 0

    def _generate_category_budgets(
        self, 
        spending_patterns: Dict, 
        period_income: float,
        period_type: str
    ) -> Dict[str, float]:
        # Define base priorities for any category that might appear
        category_priorities = {
            # Essential needs
            "Rent/Mortgage": {"priority": 1, "min_percent": 25, "max_percent": 35},
            "Utilities": {"priority": 1, "min_percent": 5, "max_percent": 10},
            "Groceries": {"priority": 1, "min_percent": 10, "max_percent": 15},
            "Healthcare": {"priority": 1, "min_percent": 5, "max_percent": 10},
            "Insurance": {"priority": 1, "min_percent": 5, "max_percent": 10},
            "Taxes": {"priority": 1, "min_percent": 15, "max_percent": 30},
            
            # Transportation
            "Transportation": {"priority": 2, "min_percent": 2, "max_percent": 5},
            "Fuel": {"priority": 2, "min_percent": 3, "max_percent": 5},
            "Car Maintenance": {"priority": 2, "min_percent": 2, "max_percent": 4},
            "Public Transit": {"priority": 2, "min_percent": 2, "max_percent": 5},
            "Taxi": {"priority": 2, "min_percent": 1, "max_percent": 3},
            
            # Financial goals
            "Debt Repayment": {"priority": 1, "min_percent": 10, "max_percent": 20},
            "Bank Fees": {"priority": 2, "min_percent": 0, "max_percent": 1},
            
            # Personal development
            "Courses": {"priority": 3, "min_percent": 1, "max_percent": 3},
            "Books": {"priority": 3, "min_percent": 1, "max_percent": 2},
            "Online Learning": {"priority": 3, "min_percent": 1, "max_percent": 3},
            
            # Discretionary spending
            "Dining Out": {"priority": 3, "min_percent": 5, "max_percent": 8},
            "Home Maintenance": {"priority": 2, "min_percent": 2, "max_percent": 5},
            "Clothing": {"priority": 3, "min_percent": 2, "max_percent": 5},
            "Fitness": {"priority": 3, "min_percent": 1, "max_percent": 3},
            "Personal Care": {"priority": 3, "min_percent": 2, "max_percent": 4},
            "Streaming Services": {"priority": 4, "min_percent": 1, "max_percent": 2},
            "Movies/Concerts": {"priority": 4, "min_percent": 1, "max_percent": 3},
            "Hobbies": {"priority": 4, "min_percent": 1, "max_percent": 3},
            "Subscriptions": {"priority": 4, "min_percent": 1, "max_percent": 2},
            "Gifts": {"priority": 3, "min_percent": 1, "max_percent": 3},
            "Charity": {"priority": 3, "min_percent": 1, "max_percent": 5},
            "Travel": {"priority": 4, "min_percent": 2, "max_percent": 8},
            "Electronics": {"priority": 4, "min_percent": 1, "max_percent": 4},
            "Other Expenses": {"priority": 4, "min_percent": 1, "max_percent": 5}
        }
        
        # Calculate the divisor for period adjustment
        divisor = self._get_period_divisor(1, period_type)
        
        # Initialize budgets dictionary
        budgets = {}
        remaining_income = period_income * 0.9  # Reserve 10% for savings
        
        # Only process categories that exist in spending patterns
        active_categories = {}
        total_spending = 0
        
        for category, pattern in spending_patterns.items():
            avg_spend = pattern["total"] * divisor
            total_spending += avg_spend
            
            # Use default priority settings if available, otherwise set as lowest priority
            priority_settings = category_priorities.get(category, {
                "priority": 4,
                "min_percent": 1,
                "max_percent": 5
            })
            
            active_categories[category] = {
                "avg_spend": avg_spend,
                "frequency": pattern["frequency"],
                "priority": priority_settings["priority"],
                "min_percent": priority_settings["min_percent"],
                "max_percent": priority_settings["max_percent"]
            }
        
        # Allocate budget by priority levels for active categories only
        for priority in range(1, 5):  # Process priorities from highest (1) to lowest (4)
            priority_categories = {
                cat: stats for cat, stats in active_categories.items() 
                if stats["priority"] == priority
            }
            
            for category, stats in priority_categories.items():
                # Calculate suggested budget based on historical spending proportion
                spending_proportion = stats["avg_spend"] / total_spending if total_spending > 0 else 0
                suggested_amount = period_income * spending_proportion
                
                # Apply minimum and maximum constraints
                min_amount = (period_income * stats["min_percent"]) / 100
                max_amount = (period_income * stats["max_percent"]) / 100
                
                # Find appropriate budget amount
                if stats["avg_spend"] > 0:
                    # Use historical spending as a base, but constrain within min-max range
                    actual_budget = min(max(suggested_amount, min_amount), max_amount)
                else:
                    # If no spending history, use minimum recommended amount
                    actual_budget = min_amount
                
                # Ensure we don't exceed remaining income
                actual_budget = min(actual_budget, remaining_income)
                budgets[category] = round(actual_budget, 2)
                remaining_income -= actual_budget
        
        # If there's remaining income, distribute proportionally to existing categories
        if remaining_income > 0:
            total_allocated = sum(budgets.values())
            for category in budgets:
                proportion = budgets[category] / total_allocated if total_allocated > 0 else 0
                extra_amount = remaining_income * proportion
                budgets[category] = round(budgets[category] + extra_amount, 2)
        
        return budgets

    def _generate_recommendations(
        self, 
        spending_patterns: Dict, 
        category_budgets: Dict[str, float],
        period_type: str
    ) -> List[str]:
        recommendations = []
        period_text = 'daily' if period_type == 'daily' else 'monthly' if period_type == 'monthly' else 'yearly'
        divisor = self._get_period_divisor(1, period_type)
        
        # Analyze categories that exist in spending patterns
        for category, pattern in spending_patterns.items():
            avg = pattern["total"] * divisor
            budget = category_budgets.get(category, 0)
            
            if avg > budget:
                reduction = avg - budget
                percentage = (reduction / avg) * 100
                recommendations.append(
                    f"Consider reducing {period_text} {category} expenses by "
                    f"${reduction:.2f} ({percentage:.1f}%)"
                )
            
            if pattern["max"] > budget * 1.5:
                recommendations.append(
                    f"Large irregular expenses detected in {category}. "
                    f"Consider setting aside a {period_text} buffer for unexpected costs."
                )
        
        return recommendations

# FastAPI router endpoint
@router.get("/budget-plan")
async def get_budget_plan(
    user_id: str = Depends(get_current_user),
    period_type: str = Query(default='monthly', regex='^(daily|monthly|yearly)$')
):
    service = AIBudgetService(user_id)
    budget_plan = service.generate_budget_plan(period_type)
    return budget_plan