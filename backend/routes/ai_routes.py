from fastapi import APIRouter, HTTPException, Query, Depends
from fastapi.responses import JSONResponse
from database import transactions_collection, goals_collection
from utils import get_current_user
from datetime import datetime, timedelta
from sklearn.linear_model import LinearRegression
import numpy as np
import pandas as pd

router = APIRouter()


# Add translation dictionary
TRANSLATIONS = {
    'en': {
        'forecast_insights': {
            'negative_cash_flow': "Critical: Monthly expenses (${average_expenses:.0f}) exceed income (${average_income:.0f}). Immediate action required to balance your budget.",
            'high_expenses': "Warning: Your expenses consume {expense_to_income_ratio:.1f}% of income, leaving little room for savings and emergencies.",
            'declining_income': "Caution: Your income shows a declining trend of {income_trend:.1f}% over the forecast period.",
            'low_savings': "Notice: Your savings rate of {savings_rate:.1f}% is below the recommended 20%. Consider optimizing expenses.",
            'positive': "Positive: Your finances show healthy patterns with a {savings_rate:.1f}% savings rate and balanced expense ratio."
        },
        'alerts': {
            'deficit': {
                'message': "Monthly deficit of ${deficit:.2f}",
                'action': "Review and cut non-essential expenses immediately"
            },
            'low_savings': {
                'message': "Critically low savings rate",
                'action': "Increase emergency fund contributions"
            }
        },
        'recommendations': {
            'budget_high_growth': "Your {category} expenses are growing rapidly (+{category_trend:.1f}%). Review and set a budget cap.",
            'budget_high_proportion': "Your {category} expenses represent {category_proportion:.1f}% of total spending. Research alternatives or negotiate better rates.",
            'goal_at_risk': "Increase monthly savings by ${gap_amount:.2f} to stay on track for {goal_name}."
        },
        'opportunity_areas': {
            'investment': "${potential_investment:.2f} monthly available for additional investments",
            'cost_optimization': "Large expense categories identified with growth trend",
            'income_growth': "Explore additional income streams or career development"
        }
    },
    'my': {
        'forecast_insights': {
            'negative_cash_flow': "သတိပေးချက်: လစဉ်အသုံးစရိတ် (${average_expenses:.0f}) သည် ဝင်ငွေ (${average_income:.0f}) ထက်ပိုများနေသည်။ သင့်အသုံးစရိတ်ကို ချက်ချင်းလျော့ချရန်လိုအပ်နေပါသည်။။",
            'high_expenses': "သတိပေးချက်: သင်၏အသုံးစရိတ်သည် ဝင်ငွေ၏ {expense_to_income_ratio:.1f}% ကိုသုံးစွဲနေပြီး ငွေစုရန်နှင့် အရေးပေါ်အတွက်ငွေအနည်းငယ်သာကျန်ရှိသည်။",
            'declining_income': "သတိပေးချက်: သင့်ဝင်ငွေသည် ခန့်မှန်းကာလအတွင်း {income_trend:.1f}% လျော့နည်းသွားမည်ဟု ပြသနေသည်။",
            'low_savings': "သတိပေးချက်: သင်၏ငွေစုနှုန်း {savings_rate:.1f}% သည် အကြံပြုထားသော 20% အောက်တွင်ရှိနေသည်။ အသုံးစရိတ်များကို လျော့ချရန် ပြင်ဆင်ပါ။",
            'positive': "Positive: သင်၏ ငွေကြေးအခြေအနေသည် {savings_rate:.1f}% ငွေစုနှုန်းနှင့် အသုံးစရိတ် အချိုးကျနေသဖြင့် အဆင်ပြေနေပါသည်။"
        },
        'alerts': {
            'deficit': {
                'message': "လစဉ်မလုံလောက်ငွေ ${deficit:.2f}",
                'action': "မလိုအပ်သောအသုံးစရိတ်များကို ချက်ချင်းပြန်လည်သုံးသပ်ပါ"
            },
            'low_savings': {
                'message': "ငွေစုနှုန်း အလွန်နည်းနေပါသည်။",
                'action': "အရေးပေါ်ငွေစုဆောင်းမှုအား တိုးမြှင့်ပါ။"
            }
        },
        'recommendations': {
            'budget_high_growth': "{category} အသုံးစရိတ်သည် အရှိန်အဟုန်မြန်စွာ တိုးလာနေသည် (+{category_trend:.1f}%)။ ပြန်လည်သုံးသပ်ပြီး အသုံးစရိတ်ကို သတ်မှတ်ပါ။",
            'budget_high_proportion': "သင်၏ {category} အသုံးစရိတ်သည် စုစုပေါင်းအသုံးစရိတ်၏ {category_proportion:.1f}% ကိုဖြစ်သည်။ အခြားရွေးချယ်စရာများကို စူးစမ်းသုံးသပ်ပါ သို့မဟုတ် နှုန်းထားညှိနှိုင်းပါ။",
            'goal_at_risk': "သင့် ငွေစုမှုရည်မှန်းချက်{goal_name}ပြည့်မှီရန် သင်၏လစဥ်ငွေစုနှုန်းကို ${gap_amount:.2f} တိုးမြှင့်ပါ။"
        },
        'opportunity_areas': {
            'investment': "တစ်လလျှင် ${potential_investment:.2f} သည် အပိုရင်းနှီးမြုပ်နှံမှုအတွက်ရနိုင်သည်",
            'cost_optimization': "အသုံးစရိတ်များသော အမျိုးအစားများကို ခွဲခြမ်းစိတ်ဖြာပြထားခြင်း",
            'income_growth': "နောက်ထပ်ဝင်ငွေအရင်းအမြစ်များနှင့် အသက်မွေးဝမ်းကြောင်းအသစ်များကို စူးစမ်းပါ"
        }
    }
}


def generate_insights_and_recommendations(forecast_data: dict, language: str = 'en') -> dict:
    # Ensure language is supported, default to English
    language = language if language in TRANSLATIONS else 'en'

    insights = {
        'forecast_insight': None,
        'recommendations': [],
        'risk_level': None,
        'opportunity_areas': [],
        'key_metrics': {},  # New section for important financial metrics
        'alerts': []  # New section for immediate attention items
    }
    
    try:
        # Extract forecast components
        income_forecast = forecast_data['income_forecast']
        expense_forecast = forecast_data['expense_forecast']
        savings_forecast = forecast_data['savings_forecast']
        category_forecasts = forecast_data['category_forecasts']
        goal_projections = forecast_data['goal_projections']

        # Calculate enhanced metrics
        income_trend = calculate_trend([f['amount'] for f in income_forecast])
        expense_trend = calculate_trend([f['amount'] for f in expense_forecast])
        savings_trend = calculate_trend([f['amount'] for f in savings_forecast])
        
        recent_months = 3
        recent_income = [f['amount'] for f in income_forecast[:recent_months]]
        recent_expenses = [f['amount'] for f in expense_forecast[:recent_months]]
        
        average_income = sum(recent_income) / len(recent_income)
        average_expenses = sum(recent_expenses) / len(recent_expenses)
        average_savings = sum(f['amount'] for f in savings_forecast[:recent_months]) / recent_months
        savings_rate = (average_savings / average_income) * 100 if average_income > 0 else 0
        expense_to_income_ratio = (average_expenses / average_income * 100) if average_income > 0 else 0

        # Store key metrics
        insights['key_metrics'] = {
            'savings_rate': round(savings_rate, 1),
            'expense_ratio': round(expense_to_income_ratio, 1),
            'income_trend': round(income_trend, 1),
            'expense_trend': round(expense_trend, 1),
            'savings_trend': round(savings_trend, 1),
            'monthly_savings': round(average_savings, 2)
        }

        # Enhanced risk assessment
        risk_factors = []
        if average_income < average_expenses:
            risk_factors.append('negative_cash_flow')
        if savings_rate < 10:
            risk_factors.append('low_savings')
        if expense_to_income_ratio > 80:
            risk_factors.append('high_expenses')
        if income_trend < -5:
            risk_factors.append('declining_income')
        
        # Determine risk level based on number of risk factors
        if len(risk_factors) >= 3:
            insights['risk_level'] = 'High'
        elif len(risk_factors) >= 1:
            insights['risk_level'] = 'Medium'
        else:
            insights['risk_level'] = 'Low'

        translation = TRANSLATIONS[language]

        # Generate main insight based on the most critical factor
        if 'negative_cash_flow' in risk_factors:
            insights['forecast_insight'] = translation['forecast_insights']['negative_cash_flow'].format(
                average_expenses=average_expenses, 
                average_income=average_income
            )
        elif 'high_expenses' in risk_factors:
            insights['forecast_insight'] = translation['forecast_insights']['high_expenses'].format(
                expense_to_income_ratio=expense_to_income_ratio
            )
        elif 'declining_income' in risk_factors:
            insights['forecast_insight'] = translation['forecast_insights']['declining_income'].format(
                income_trend=income_trend
            )
        elif 'low_savings' in risk_factors:
            insights['forecast_insight'] = translation['forecast_insights']['low_savings'].format(
                savings_rate=savings_rate
            )
        else:
            insights['forecast_insight'] = translation['forecast_insights']['positive'].format(
                savings_rate=savings_rate
            )

        # Generate immediate alerts for critical situations
        if average_expenses > average_income:
            deficit = average_expenses - average_income
            insights['alerts'].append({
                'type': 'critical',
                'message': translation['alerts']['deficit']['message'].format(deficit=deficit),
                'action': translation['alerts']['deficit']['action']
            })
        
        if savings_rate < 5:
            insights['alerts'].append({
                'type': 'warning',
                'message': translation['alerts']['low_savings']['message'],
                'action': translation['alerts']['low_savings']['action']
            })

        # Translate recommendations
        if 'expense' in category_forecasts:
            expense_categories = category_forecasts['expense']
            total_expenses = sum(cat[-1]['amount'] for cat in expense_categories.values())
            
            for category, data in expense_categories.items():
                category_trend = calculate_trend([f['amount'] for f in data])
                category_proportion = (data[-1]['amount'] / total_expenses) * 100
                
                if category_trend > 15:
                    insights['recommendations'].append({
                        'category': category,
                        'priority': 'High' if category_proportion > 20 else 'Medium',
                        'action': translation['recommendations']['budget_high_growth'].format(
                            category=category, 
                            category_trend=category_trend
                        ),
                        'impact': f"Controls {category_proportion:.1f}% of total expenses"
                    })
                
                if category_proportion > 30:
                    insights['recommendations'].append({
                        'category': category,
                        'priority': 'High',
                        'action': translation['recommendations']['budget_high_proportion'].format(
                            category=category, 
                            category_proportion=category_proportion
                        ),
                        'impact': "Potential for significant monthly savings"
                    })

        # Enhanced goal achievement analysis
        for goal in goal_projections:
            probability = goal['probability']
            monthly_required = goal['monthly_required']
            
            if probability < 50:
                gap_amount = monthly_required - average_savings
                shortfall_months = calculate_shortfall_months(gap_amount, savings_forecast)
                
                insights['recommendations'].append({
                    'category': 'Goals',
                    'priority': 'High' if probability < 30 else 'Medium',
                    'action': translation['recommendations']['goal_at_risk'].format(
                        gap_amount=gap_amount, 
                        goal_name=goal['name']
                    ),
                    'impact': f"Goal at risk without adjustment for {shortfall_months} months"
                })

        # Enhanced opportunity identification
        if savings_rate > 20:
            potential_investment = (savings_rate - 20) * average_income / 100
            insights['opportunity_areas'].append({
                'category': 'Investment',
                'description': translation['opportunity_areas']['investment'].format(
                    potential_investment=potential_investment
                ),
                'potential_impact': "Long-term wealth building through diversified investments"
            })
        
        if expense_trend > 0 and any(cat['amount'] > average_expenses * 0.3 for cat in find_top_categories(category_forecasts['expense'])):
            insights['opportunity_areas'].append({
                'category': 'Cost Optimization',
                'description': translation['opportunity_areas']['cost_optimization'],
                'potential_impact': f"Potential ${(average_expenses * 0.1):.2f} monthly savings through optimization"
            })

        if income_trend <= 2:
            insights['opportunity_areas'].append({
                'category': 'Income Growth',
                'description': translation['opportunity_areas']['income_growth'],
                'potential_impact': "Increase financial stability and accelerate goal achievement"
            })

        # Sort recommendations by priority
        insights['recommendations'].sort(key=lambda x: {'High': 0, 'Medium': 1, 'Low': 2}[x['priority']])

    except Exception as e:
        insights['forecast_insight'] = "Unable to generate detailed insights at this time."
        insights['recommendations'].append({
            'category': 'System',
            'priority': 'High',
            'action': "Please ensure your financial data is up to date and try again.",
            'impact': "Required for accurate analysis"
        })

    return insights

def calculate_shortfall_months(gap_amount: float, savings_forecast: list) -> int:
    """Calculate number of months where savings fall short of required amount"""
    return sum(1 for month in savings_forecast if month['amount'] < gap_amount)

# Existing helper functions remain unchanged
def calculate_trend(values: list) -> float:
    """Calculate the trend (percentage change) in a series of values"""
    if not values or len(values) < 2:
        return 0.0
    total_change = ((values[-1] - values[0]) / values[0]) * 100
    return total_change

def find_high_growth_categories(categories: dict, threshold: float = 10.0) -> list:
    """Identify categories with growth rate above threshold"""
    high_growth = []
    for category, data in categories.items():
        if len(data) >= 2:
            growth = calculate_trend([f['amount'] for f in data])
            if growth > threshold:
                high_growth.append((category, growth))
    return high_growth

def find_top_categories(categories: dict, top_n: int = 3) -> list:
    """Find the top N categories by amount"""
    if not categories:
        return []
    
    category_totals = []
    for category, data in categories.items():
        if data:
            total = sum(f['amount'] for f in data)
            category_totals.append({'category': category, 'amount': total})
    
    return sorted(category_totals, key=lambda x: x['amount'], reverse=True)[:top_n]


@router.get("/financial-forecast")
def get_financial_forecast(
    user_id: str = Depends(get_current_user),
    forecast_months: int = Query(default=6, ge=1, le=24),
    language: str = Query(default='en', regex='^(en|my)$')
):
    try:
        # Get historical transactions
        transactions = list(transactions_collection.find({"user_id": user_id}))
        if not transactions:
            raise HTTPException(status_code=404, detail="No transaction history found")

        # Convert to DataFrame
        df = pd.DataFrame(transactions)
        df['date'] = pd.to_datetime(df['date'])
        df['amount'] = df['amount'].astype(float)

        # Separate income and expenses
        income_df = df[df['type'] == 'income'].copy()
        expense_df = df[df['type'] == 'expense'].copy()

        # Group by month
        monthly_income = income_df.groupby(pd.Grouper(key='date', freq='M'))['amount'].sum().reset_index()
        monthly_expenses = expense_df.groupby(pd.Grouper(key='date', freq='M'))['amount'].sum().reset_index()

        # Prepare data for forecasting
        income_forecast = forecast_time_series(monthly_income, forecast_months)
        expense_forecast = forecast_time_series(monthly_expenses, forecast_months)
        
        # Get category-wise forecasts
        income_categories = income_df['category'].unique()
        expense_categories = expense_df['category'].unique()
        
        category_forecasts = {
            'income': {},
            'expense': {}
        }
        
        # Forecast for each income category
        for category in income_categories:
            cat_data = income_df[income_df['category'] == category]
            monthly_cat = cat_data.groupby(pd.Grouper(key='date', freq='M'))['amount'].sum().reset_index()
            category_forecasts['income'][category] = forecast_time_series(monthly_cat, forecast_months)
            
        # Forecast for each expense category
        for category in expense_categories:
            cat_data = expense_df[expense_df['category'] == category]
            monthly_cat = cat_data.groupby(pd.Grouper(key='date', freq='M'))['amount'].sum().reset_index()
            category_forecasts['expense'][category] = forecast_time_series(monthly_cat, forecast_months)

        # Calculate savings forecast
        savings_forecast = []
        for i in range(len(income_forecast)):
            savings_forecast.append({
                'date': income_forecast[i]['date'],
                'amount': income_forecast[i]['amount'] - expense_forecast[i]['amount']
            })

        # Get current goals for context
        goals = list(goals_collection.find({
            "user_id": user_id,
            "completed": False
        }))
        
        goal_projections = []
        for goal in goals:
            target_amount = float(goal['target_amount'])
            current_amount = float(goal['current_amount'])
            deadline = goal['deadline']
            
            # Calculate monthly required savings
            months_remaining = (deadline - datetime.now()).days / 30
            if months_remaining > 0:
                monthly_required = (target_amount - current_amount) / months_remaining
                goal_projections.append({
                    'name': goal['name'],
                    'monthly_required': monthly_required,
                    'probability': calculate_goal_probability(monthly_required, savings_forecast)
                })

        forecast_data = {
            'income_forecast': income_forecast,
            'expense_forecast': expense_forecast,
            'savings_forecast': savings_forecast,
            'category_forecasts': category_forecasts,
            'goal_projections': goal_projections
        }
        
        # Generate insights and recommendations
        insights = generate_insights_and_recommendations(forecast_data, language)
        
        # Add insights to the response
        forecast_data.update(insights)
        
        return JSONResponse(
        content=forecast_data, 
        media_type="application/json; charset=utf-8"
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Forecast calculation failed: {str(e)}")

def forecast_time_series(data: pd.DataFrame, forecast_months: int):
    if len(data) < 2:
        # Not enough data for forecasting, return simple projection
        if len(data) == 0:
            avg_amount = 0
        else:
            avg_amount = data['amount'].mean()
        
        future_dates = [datetime.now() + timedelta(days=30*i) for i in range(forecast_months)]
        return [{'date': date.isoformat(), 'amount': avg_amount} for date in future_dates]

    # Prepare features (X) and target (y)
    X = np.arange(len(data)).reshape(-1, 1)
    y = data['amount'].values

    # Fit linear regression model
    model = LinearRegression()
    model.fit(X, y)

    # Generate future dates
    last_date = data['date'].iloc[-1]
    future_dates = [last_date + timedelta(days=30*i) for i in range(1, forecast_months + 1)]
    
    # Predict future values
    future_X = np.arange(len(data), len(data) + forecast_months).reshape(-1, 1)
    predictions = model.predict(future_X)
    
    # Ensure no negative predictions for amounts
    predictions = np.maximum(predictions, 0)

    # Format results
    return [
        {'date': date.isoformat(), 'amount': float(amount)}
        for date, amount in zip(future_dates, predictions)
    ]

def calculate_goal_probability(monthly_required: float, savings_forecast: list) -> float:
    if not savings_forecast:
        return 0.0
        
    # Calculate how many months the forecasted savings meet the required amount
    successful_months = sum(1 for month in savings_forecast 
                          if month['amount'] >= monthly_required)
    
    # Calculate probability as percentage of successful months
    probability = (successful_months / len(savings_forecast)) * 100
    
    return round(probability, 2)


