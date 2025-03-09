from calendar import monthrange

from fastapi.encoders import jsonable_encoder
from fastapi.responses import JSONResponse
from database import transactions_collection
from datetime import datetime, timedelta
from typing import Dict, List
import statistics

from fastapi import APIRouter, Depends, Query
from models.budget_plan_model import BudgetPlan
from utils import get_current_user

router = APIRouter()


TRANSLATIONS = {
    'en': {
        'recommendations': {
            'high_essential_expenses': "Your essential expenses are taking up {essentials_ratio:.1%} of your budget. Consider finding ways to reduce basic living costs or increase income through additional revenue streams.",
            'low_savings_rate': "Your current savings rate is {savings_ratio:.1%}. Try to increase your savings to at least 15% of income by reducing non-essential expenses.",
            'variability_in_spending': "Your {category} spending shows high variation. Consider setting up a separate {category} fund to manage irregular expenses better",
            'high_grocery_spending': "Consider meal planning and bulk buying to reduce {period_text} grocery expenses by ${savings:.2f}. Local markets often offer better prices than supermarkets.",
            'high_dining_out': "Your {period_text} dining out expenses are {overage_percentage:.0%} over budget. Try cooking at home more often and limiting restaurant visits to special occasions.",
            'high_utility_costs': "Your utility bills are higher than budgeted. Consider energy-efficient appliances and mindful usage during peak hours to reduce costs.",
            'low_emergency_fund': "Your emergency fund allocation is below recommended levels. Aim to save at least 5% of your income for unexpected expenses.",
            'rainy_season_prep': "Rainy season is approaching. Consider setting aside extra funds for transportation and healthcare, and ensure emergency funds are adequate.",
            'festival_season_prep': "Festival season is coming up. Plan ahead for additional charitable giving and gift expenses while maintaining your essential savings goals.",
            'thingyan_prep': "With Thingyan approaching, consider allocating funds for festivities while maintaining a balance with your regular savings and essential expenses.",
            'hot_season_tips': "During hot season, you might see increased utility costs. Consider using fans instead of air conditioning when possible and maintaining your cooling systems for better efficiency."
        }
    },
    'my': {
        'recommendations': {
            'high_essential_expenses': "သင့်သည် သင့်လစာ၏ {essentials_ratio:.1%} ကို နေ့စဉ်အသုံးပြုနေပါသည်။ မလိုအပ်သော ကုန်ကျစရိတ်များကို လျှော့ချပါ သို့မဟုတ် အပိုဝင်ငွေရှာရန် နည်းလမ်းများကို ရှာဖွေပါ။ ",
            'low_savings_rate': "သင်၏နေ့စဉ်ငွေစုနှုန်းသည် {savings_ratio:.1%} ဖြစ်ပါသည်။မလိုအပ်သောအသုံးစရိတ်များကို လျှော့ချခြင်းဖြင့် ဝင်ငွေ၏ အနည်းဆုံး 15% အထိ ငွေစုနှုန်းကို မြှင့်တင်ကြည့်ပါ။",
            'variability_in_spending': "သင်၏ {category} အပေါ်အသုံးစရိတ်သည် အပြောင်းအလဲများရှိနေသည်။ သီးခြား {category} အသုံးစရိတ်များထားခြင်းဖြင့် သင့်ရဲ့ မလိုအပ်သော အသုံးအဖြုန်းစရိတ်များကို လျှော့ချလိုက်ပါ။",
            'high_grocery_spending' : "{period_text} ကုန်ကျစရိတ်ကို ${savings:.2f} လျှော့ချရန် သင့်၏နေ့စဉ်စားသောက်ခြင်းနှင့် အများအပြားဝယ်ယူခြင်းကို တတ်နိုင်သမျှလျှော့ချပါ။ ဒေသတွင်းဈေးများသည် စူပါမားကတ်များထက် ဈေးနှုန်းပိုသက်သာလေ့ရှိပါသည်။",
            'high_dining_out': "သင့်ရဲ့ {period_text} အပြင်စာစားသုံးစရိတ်သည် ဘတ်ဂျက်ထက် {overage_percentage:.0%} ပိုနေပါသည်။ နေ့ထူးနေ့ရက်များမှာသာ အပြင်စားသောက်ဆိုင်များတွင် စားသုံးပြီး အချို့ရက်များတွင် အိမ်တွက် ချက်ပြုတ်စားသောက်ခြင်းက သင့်အတွက်ပိုမိုသင့်တော်စေပါသည်။",
            'high_utility_costs': "သင့်၏မီတာခသုံးစွဲမှုသည် သင့်ဘတ်ဂျက်ထက်ပို၍သုံးစွဲမိနေပါသည်။ လျှပ်စစ်စွမ်းအား ချွေတာသည့် ပစ္စည်းများ သို့မဟုတ် မလိုအပ်သည့်အချိန်များတွင် လျှပ်စစ်စွမ်းအား အသုံးပြုခြင်းကိုလျှော့ချခြင်းဖြင့် သင့်၏မီတာခ အလွန်အကျွံကုန်ကျနေခြင်းကို လျှော့ချနိုင်ပါသည်။",
            'low_emergency_fund': "သင့်အနေနဲ့ အရေးပေါ်အခြေအနေများအတွက် လုံလုံလောက်လောက် စုဆောင်းထားမှုမရှိပါ။  မမျှော်လင့်ထားသော ကုန်ကျစရိတ်များအတွက် သင့်ဝင်ငွေရဲ့ အနည်းဆုံး ၅% ကို ချန်ထားဖို့ ကြိုးစားကြည့်ပါ။",
            'rainy_season_prep': "မကြာမီ မိုးရာသီရောက်တော့မှာဖြစ်သောကြောင့် သင့်၏သွားရေးလာရေး ကျန်းမာရေး စသည့် အရေးပေါ်အခြအနေများအတွက် အသုံးပြုရန် ငွေအချို့ဖယ်ထားခြင်းက သင့်ကို အထောက်အကူဖြစ်စေမှာပါ။",
            'festival_season_prep': "“ပွဲတော်ရာသီ ရောက်လာတော့မယ်။ လက်ဆောင်နှင့် လှူဒါန်းမှုများအတွက် အပိုသုံးစွဲမှုကို သေချာစိစစ်ပြီး သင့်စုဆောင်းငွေပန်းတိုင်များကိုလည်း ဆက်လက်ထိန်းသိမ်းပါ။”",
            'thingyan_prep': "မကြာမီ သင်္ကြန်ရောက်ရှိလာပါတော့မယ်။ ပွဲတော်တွင် အသုံးပြုရန်အတွက်အသုံးစရိတ်များကိုဖယ်ထားပြီး သင့်၏ ငွေစုနှုန်းနှင့်အရေးကြီးသောအသုံးစရိတ်များကိုလည်း ထိန်းသိမ်းထားပါ။",
            'hot_season_tips': "နွေရာသီတွင် မီတာခအသုံးစရိတ် ပိုမိုကုန်ကျနိုင်တဲ့အတွက်ကြောင့် လျှပ်စစ်ပစ္စည်းများသုံးစွဲမှုလျှော့ချပါ။ (ဥပမာ အဲယားကွန်း အစား ပန်ကာကိုအသုံးပြုပါ။)"
        }
    }
}

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
        # Updated category priorities based on Myanmar living expenses
        # Modified from 50/30/20 to 60/25/15 rule to account for higher essential expenses
        category_priorities = {
            # Needs (Essential) - Target: 60% of income
            "Groceries": {"priority": 1, "min_percent": 20, "max_percent": 30, "category_type": "needs"},  # Higher food allocation
            "Rent/Mortgage": {"priority": 1, "min_percent": 15, "max_percent": 25, "category_type": "needs"},
            "Public Transit": {"priority": 1, "min_percent": 8, "max_percent": 12, "category_type": "needs"}, 
            "Taxi": {"priority": 1, "min_percent": 8, "max_percent": 12, "category_type": "needs"},  
            "Utilities": {"priority": 1, "min_percent": 5, "max_percent": 10, "category_type": "needs"},  # Electricity, water
            "Healthcare": {"priority": 1, "min_percent": 5, "max_percent": 8, "category_type": "needs"},
            "Education fees": {"priority": 1, "min_percent": 5, "max_percent": 10, "category_type": "needs"},  # High priority in Myanmar
            
            # Wants (Lifestyle) - Target: 25% of income
            "Dining Out": {"priority": 2, "min_percent": 3, "max_percent": 6, "category_type": "wants"},
            "Shopping": {"priority": 2, "min_percent": 2, "max_percent": 5, "category_type": "wants"},
            "Clothing": {"priority": 2, "min_percent": 2, "max_percent": 5, "category_type": "wants"},
            "Movies/Concerts": {"priority": 2, "min_percent": 2, "max_percent": 4, "category_type": "wants"},
            "Personal Care": {"priority": 2, "min_percent": 2, "max_percent": 4, "category_type": "wants"},
            "Charity": {"priority": 2, "min_percent": 2, "max_percent": 5, "category_type": "wants"},  # Important in Myanmar culture
            "Family Support": {"priority": 2, "min_percent": 3, "max_percent": 6, "category_type": "wants"},  # Cultural obligation
            
            # Savings/Investment - Target: 15% of income
            "Emergency Fund": {"priority": 1, "min_percent": 5, "max_percent": 8, "category_type": "savings"},
            "Gold/Jewelry": {"priority": 2, "min_percent": 2, "max_percent": 5, "category_type": "savings"},  # Common saving method
            "Business Investment": {"priority": 2, "min_percent": 2, "max_percent": 5, "category_type": "savings"},
            "Insurance": {"priority": 2, "min_percent": 1, "max_percent": 3, "category_type": "savings"},
            "Digital Assets": {"priority": 2, "min_percent": 1, "max_percent": 3, "category_type": "savings"},  # Growing trend
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
                    "category_type": "wants"
                })
            }
        
        # Second pass: Allocate budgets based on 60/25/15 rule (Myanmar adjusted)
        target_allocations = {
            "needs": 0.6 * period_income,  # Increased to 60%
            "wants": 0.25 * period_income, # Reduced to 25%
            "savings": 0.15 * period_income # Reduced to 15%
        }
        
        # Sort categories by priority and historical spending
        sorted_categories = sorted(
            spending_analysis.items(),
            key=lambda x: (
                x[1]["settings"]["priority"],
                -x[1]["avg_spend"]
            )
        )
        
        # Allocate budgets
        for category, analysis in sorted_categories:
            settings = analysis["settings"]
            category_type = settings["category_type"]
            
            min_amount = (period_income * settings["min_percent"]) / 100
            max_amount = (period_income * settings["max_percent"]) / 100
            
            if analysis["avg_spend"] > 0:
                # Adjust weights to favor historical spending more in Myanmar context
                historical_weight = 0.8  # Increased from 0.7
                recommended_weight = 0.2  # Decreased from 0.3
                
                recommended_amount = (min_amount + max_amount) / 2
                suggested_budget = (
                    analysis["avg_spend"] * historical_weight +
                    recommended_amount * recommended_weight
                )
                
                suggested_budget = max(min_amount, min(suggested_budget, max_amount))
            else:
                suggested_budget = min_amount
            
            remaining_type_allocation = target_allocations[category_type] - category_totals[category_type]
            suggested_budget = min(suggested_budget, remaining_type_allocation)
            suggested_budget = min(suggested_budget, remaining_income)
            
            budgets[category] = round(suggested_budget, 2)
            remaining_income -= suggested_budget
            category_totals[category_type] += suggested_budget
        
        # Final pass: Adjust for Myanmar seasonal variations
        current_month = datetime.utcnow().month
        seasonal_adjustments = {
            # Rainy Season (June to October)
            6: {"Public Transit": 1.2, "Taxi": 1.2, "Healthcare": 1.1},  # Increased transport costs
            7: {"Public Transit": 1.2, "Taxi": 1.2,  "Healthcare": 1.1},
            8: {"Public Transit": 1.2, "Taxi": 1.2,  "Healthcare": 1.1},
            9: {"Public Transit": 1.2, "Taxi": 1.2,  "Healthcare": 1.1},
            10: {"Public Transit": 1.2, "Taxi": 1.2,  "Healthcare": 1.1},
            
            # Festival Season (October to November)
            10: {"Charity": 1.3, "Shopping": 1.2},  # Thadingyut
            11: {"Charity": 1.3, "Shopping": 1.2},  # Tazaungdaing
            
            # Hot Season (March to May)
            3: {"Utilities": 1.2},  # Higher electricity for cooling
            4: {"Utilities": 1.3, "Healthcare": 1.1},
            5: {"Utilities": 1.3, "Healthcare": 1.1},
            
            # Myanmar New Year (April)
            4: {"Charity": 1.4, "Shopping": 1.3},  # Thingyan adjustments
        }
        
        # Apply seasonal adjustments
        if current_month in seasonal_adjustments:
            for category, multiplier in seasonal_adjustments[current_month].items():
                if category in budgets:
                    adjusted_budget = budgets[category] * multiplier
                    if adjusted_budget <= remaining_income + budgets[category]:
                        remaining_income -= (adjusted_budget - budgets[category])
                        budgets[category] = round(adjusted_budget, 2)
        
        # Distribute remaining income to emergency fund and gold/jewelry
        if remaining_income > 0:
            priority_savings = ["Emergency Fund", "Gold/Jewelry"]
            available_savings = [cat for cat in priority_savings if cat in budgets]
            
            if available_savings:
                extra_per_category = remaining_income / len(available_savings)
                for category in available_savings:
                    budgets[category] = round(budgets[category] + extra_per_category, 2)
        
        return budgets
    

    @staticmethod
    def _get_recommendation(translation_key: str, language: str = 'en', **kwargs):
        """Retrieve a translated recommendation with provided variables"""
        language = language if language in TRANSLATIONS else 'en'
        try:
            return TRANSLATIONS[language]['recommendations'][translation_key].format(**kwargs)
        except (KeyError, ValueError):
            # Fallback to English if translation fails
            return TRANSLATIONS['en']['recommendations'][translation_key].format(**kwargs)
        

    # Modify the _generate_recommendations method to use the new translation function
    def _generate_recommendations(
        self, 
        spending_patterns: Dict, 
        category_budgets: Dict[str, float],
        period_type: str,
        language: str = 'en'  # Add language parameter
    ) -> List[str]:
        recommendations = []
        period_text = 'daily' if period_type == 'daily' else 'monthly' if period_type == 'monthly' else 'yearly'
        divisor = self._get_period_divisor(1, period_type)
        
        # Track overall financial health indicators
        total_income = sum(cat_budget for cat_budget in category_budgets.values())
        if total_income == 0:  # Add safety check for zero total income
            return ["No budget data available for recommendations."]
            
        essential_categories = {
            'Groceries', 'Rent/Mortgage', 'Utilities', 'Healthcare', 
            'Public Transit', 'Taxi', 'Education fees'
        }
        wants_categories = {
            'Dining Out', 'Shopping', 'Entertainment', 'Personal Care',
            'Movies/Concerts', 'Clothing'
        }
        savings_categories = {
            'Emergency Fund', 'Gold/Jewelry', 'Business Investment',
            'Insurance', 'Digital Assets'
        }
        
        # Calculate category type totals
        essentials_total = sum(category_budgets.get(cat, 0) for cat in essential_categories)
        wants_total = sum(category_budgets.get(cat, 0) for cat in wants_categories)
        savings_total = sum(category_budgets.get(cat, 0) for cat in savings_categories)
        
        # Check overall budget distribution
        essentials_ratio = essentials_total / total_income if total_income > 0 else 0
        wants_ratio = wants_total / total_income if total_income > 0 else 0
        savings_ratio = savings_total / total_income if total_income > 0 else 0
        
        # Generate high-level financial health recommendations
        if essentials_ratio > 0.65:
            recommendations.append(
                self._get_recommendation(
                    'high_essential_expenses', 
                    language=language, 
                    essentials_ratio=essentials_ratio
                )
            )
        
        if savings_ratio < 0.15:
            recommendations.append(
                self._get_recommendation(
                    'low_savings_rate', 
                    language=language, 
                    savings_ratio=savings_ratio
                )
            )
        
        # Analyze spending patterns and trends
        for category, pattern in spending_patterns.items():
            avg_spending = pattern["total"] * divisor
            budget = category_budgets.get(category, 0)
            
            # Skip recommendations for categories with zero budget
            if budget == 0:
                continue
                
            frequency = pattern["frequency"]

            # Calculate variability in spending
            if len(pattern.get("amounts", [])) > 1:
                try:
                    coefficient_variation = statistics.stdev(pattern["amounts"]) / statistics.mean(pattern["amounts"])
                    
                    if coefficient_variation > 0.5 and category in essential_categories:
                        recommendations.append(
                            self._get_recommendation(
                                'variability_in_spending', 
                                language=language, 
                                category=category
                            )
                        )
                except statistics.StatisticsError:
                    # Handle case where there's not enough data for statistical calculation
                    continue
            
            
            # Category-specific intelligent recommendations
            if category == "Groceries" and avg_spending > budget * 1.2:
                recommendations.append(
                    self._get_recommendation(
                        'high_grocery_spending', 
                        language=language, 
                        period_text=period_text, 
                        savings=avg_spending - budget
                    )
                )
            
            elif category == "Dining Out" and avg_spending > budget * 1.3:
                recommendations.append(
                    self._get_recommendation(
                        'high_dining_out', 
                        language=language, 
                        period_text=period_text, 
                        overage_percentage=(avg_spending/budget - 1) if budget > 0 else 0
                    )
                )
            
            elif category == "Utilities" and avg_spending > budget * 1.15:
                recommendations.append(
                    self._get_recommendation(
                        'high_utility_costs', 
                        language=language
                    )
                )
            
            elif category == "Emergency Fund" and budget < total_income * 0.05:
                recommendations.append(
                    self._get_recommendation(
                        'low_emergency_fund', 
                        language=language
                    )
                )

        # Seasonal and cultural context recommendations remain unchanged...
        current_month = datetime.utcnow().month
        
        # Rainy season preparations (May-June)
        if current_month in [4, 5]:
            recommendations.append(
                self._get_recommendation(
                    'rainy_season_prep', 
                    language=language
                )
            )
        
        # Festival season preparations (October-November)
        elif current_month in [9, 10]:
            recommendations.append(
                self._get_recommendation(
                    'festival_season_prep', 
                    language=language
                )
            )
        
        # Thingyan preparation (March)
        elif current_month == 3:
            recommendations.append(
                self._get_recommendation(
                    'thingyan_prep', 
                    language=language
                )
            )
        
        # Hot season (March-May)
        elif current_month in [3, 4, 5]:
            recommendations.append(
                self._get_recommendation(
                    'hot_season_tips', 
                    language=language
                )
            )
        
        # Prioritize and limit recommendations
        recommendations = sorted(recommendations, key=lambda x: len(x))[:5]
        
        return recommendations if recommendations else ["No specific recommendations available for this period."]


@router.get("/budget-plan")
async def get_budget_plan(
    user_id: str = Depends(get_current_user),
    period_type: str = Query(default='monthly', regex='^(daily|monthly|yearly)$'),
    language: str = Query(default='en', regex='^(en|my)$')
):
    service = AIBudgetService(user_id)
    budget_plan = service.generate_budget_plan(period_type)
    
    # Add language-specific recommendations
    budget_plan.recommendations = service._generate_recommendations(
        spending_patterns=service._analyze_spending_patterns(
            service._get_historical_transactions(period_type), 
            period_type
        ),
        category_budgets=budget_plan.category_budgets,
        period_type=period_type,
        language=language
    )
    
    # Convert the budget_plan to a dictionary that can be JSON serialized
    return JSONResponse(content=jsonable_encoder(budget_plan), media_type="application/json; charset=utf-8")