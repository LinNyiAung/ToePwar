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
        # Updated category priorities based on common financial advice (50/30/20 rule)
        # 50% for needs, 30% for wants, 20% for savings/debt
        category_priorities = {
            # Needs (Essential) - Target: 50% of income
            "Rent/Mortgage": {"priority": 1, "min_percent": 25, "max_percent": 35, "category_type": "needs"},
            "Utilities": {"priority": 1, "min_percent": 5, "max_percent": 8, "category_type": "needs"},
            "Groceries": {"priority": 1, "min_percent": 8, "max_percent": 12, "category_type": "needs"},
            "Healthcare": {"priority": 1, "min_percent": 5, "max_percent": 10, "category_type": "needs"},
            "Insurance": {"priority": 1, "min_percent": 4, "max_percent": 8, "category_type": "needs"},
            "Transportation": {"priority": 1, "min_percent": 5, "max_percent": 15, "category_type": "needs"},
            
            # Wants (Lifestyle) - Target: 30% of income
            "Dining Out": {"priority": 2, "min_percent": 3, "max_percent": 7, "category_type": "wants"},
            "Entertainment": {"priority": 2, "min_percent": 2, "max_percent": 5, "category_type": "wants"},
            "Shopping": {"priority": 2, "min_percent": 2, "max_percent": 6, "category_type": "wants"},
            "Hobbies": {"priority": 2, "min_percent": 1, "max_percent": 4, "category_type": "wants"},
            "Fitness": {"priority": 2, "min_percent": 1, "max_percent": 3, "category_type": "wants"},
            "Travel": {"priority": 2, "min_percent": 2, "max_percent": 5, "category_type": "wants"},
            
            # Savings/Debt (Financial Goals) - Target: 20% of income
            "Emergency Fund": {"priority": 1, "min_percent": 5, "max_percent": 10, "category_type": "savings"},
            "Retirement": {"priority": 1, "min_percent": 5, "max_percent": 15, "category_type": "savings"},
            "Debt Repayment": {"priority": 1, "min_percent": 5, "max_percent": 20, "category_type": "savings"},
            "Investment": {"priority": 2, "min_percent": 2, "max_percent": 10, "category_type": "savings"},
        }
        
        # Calculate the divisor for period adjustment
        divisor = self._get_period_divisor(1, period_type)
        
        # Initialize budgets and category trackers
        budgets = {}
        remaining_income = period_income
        category_totals = {"needs": 0, "wants": 0, "savings": 0}
        
        # First pass: Analyze historical spending patterns
        spending_analysis = {}
        total_historical_spending = 0
        
        for category, pattern in spending_patterns.items():
            avg_spend = pattern["total"] * divisor
            total_historical_spending += avg_spend
            
            spending_analysis[category] = {
                "avg_spend": avg_spend,
                "frequency": pattern["frequency"],
                "settings": category_priorities.get(category, {
                    "priority": 2,
                    "min_percent": 1,
                    "max_percent": 5,
                    "category_type": "wants"  # Default uncategorized to wants
                })
            }
        
        # Second pass: Allocate budgets based on 50/30/20 rule
        target_allocations = {
            "needs": 0.5 * period_income,
            "wants": 0.3 * period_income,
            "savings": 0.2 * period_income
        }
        
        # Sort categories by priority and historical spending
        sorted_categories = sorted(
            spending_analysis.items(),
            key=lambda x: (
                x[1]["settings"]["priority"],
                -x[1]["avg_spend"]  # Higher spending gets priority
            )
        )
        
        # Allocate budgets
        for category, analysis in sorted_categories:
            settings = analysis["settings"]
            category_type = settings["category_type"]
            
            # Calculate suggested budget based on historical spending and limits
            min_amount = (period_income * settings["min_percent"]) / 100
            max_amount = (period_income * settings["max_percent"]) / 100
            
            # Consider historical spending in budget calculation
            if analysis["avg_spend"] > 0:
                # Use weighted average of historical spending and recommended range
                historical_weight = 0.7
                recommended_weight = 0.3
                
                recommended_amount = (min_amount + max_amount) / 2
                suggested_budget = (
                    analysis["avg_spend"] * historical_weight +
                    recommended_amount * recommended_weight
                )
                
                # Ensure within min-max bounds
                suggested_budget = max(min_amount, min(suggested_budget, max_amount))
            else:
                # No history - use recommended minimum
                suggested_budget = min_amount
            
            # Adjust for remaining allocation in category type
            remaining_type_allocation = target_allocations[category_type] - category_totals[category_type]
            suggested_budget = min(suggested_budget, remaining_type_allocation)
            
            # Ensure we don't exceed remaining total income
            suggested_budget = min(suggested_budget, remaining_income)
            
            # Update trackers
            budgets[category] = round(suggested_budget, 2)
            remaining_income -= suggested_budget
            category_totals[category_type] += suggested_budget
        
        # Final pass: Adjust for seasonal variations
        current_month = datetime.utcnow().month
        seasonal_adjustments = {
            # Winter months
            12: {"Utilities": 1.2, "Entertainment": 1.1},  # December
            1: {"Utilities": 1.2, "Clothing": 0.8},        # January
            2: {"Utilities": 1.1},                         # February
            
            # Spring months
            3: {"Home Maintenance": 1.1},                  # March
            4: {"Shopping": 1.1},                          # April
            5: {"Travel": 1.2},                            # May
            
            # Summer months
            6: {"Travel": 1.3, "Entertainment": 1.2},      # June
            7: {"Travel": 1.3, "Entertainment": 1.2},      # July
            8: {"Shopping": 1.2},                          # August
            
            # Fall months
            9: {"Shopping": 1.1, "Education": 1.2},        # September
            10: {"Home Maintenance": 1.1},                 # October
            11: {"Shopping": 1.2}                          # November
        }
        
        # Apply seasonal adjustments
        if current_month in seasonal_adjustments:
            for category, multiplier in seasonal_adjustments[current_month].items():
                if category in budgets:
                    adjusted_budget = budgets[category] * multiplier
                    if adjusted_budget <= remaining_income + budgets[category]:
                        remaining_income -= (adjusted_budget - budgets[category])
                        budgets[category] = round(adjusted_budget, 2)
        
        # Distribute any remaining income proportionally to savings categories
        if remaining_income > 0:
            savings_categories = [
                cat for cat in budgets.keys() 
                if category_priorities.get(cat, {}).get("category_type") == "savings"
            ]
            
            if savings_categories:
                extra_per_category = remaining_income / len(savings_categories)
                for category in savings_categories:
                    budgets[category] = round(budgets[category] + extra_per_category, 2)
        
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