from fastapi import APIRouter, HTTPException, Query, Depends
from database import transactions_collection, goals_collection
from utils import get_current_user
from datetime import datetime, timedelta
from sklearn.linear_model import LinearRegression
import numpy as np
import pandas as pd

router = APIRouter()


def generate_insights_and_recommendations(forecast_data: dict) -> dict:
    insights = {
        'forecast_insight': None,
        'recommendations': [],
        'risk_level': None,
        'opportunity_areas': []
    }
    
    try:
        # Extract forecast components
        income_forecast = forecast_data['income_forecast']
        expense_forecast = forecast_data['expense_forecast']
        savings_forecast = forecast_data['savings_forecast']
        category_forecasts = forecast_data['category_forecasts']
        goal_projections = forecast_data['goal_projections']

        # Calculate key metrics
        income_trend = calculate_trend([f['amount'] for f in income_forecast])
        expense_trend = calculate_trend([f['amount'] for f in expense_forecast])
        savings_trend = calculate_trend([f['amount'] for f in savings_forecast])
        
        average_income = sum(f['amount'] for f in income_forecast) / len(income_forecast)
        average_expenses = sum(f['amount'] for f in expense_forecast) / len(expense_forecast)
        average_savings = sum(f['amount'] for f in savings_forecast) / len(savings_forecast)
        savings_rate = (average_savings / average_income) * 100 if average_income > 0 else 0

        # Assess financial health and set risk level
        if average_income < average_expenses:
            insights['risk_level'] = 'High'
            insights['forecast_insight'] = "Critical: Your projected expenses exceed income, indicating significant financial stress."
        elif savings_rate < 10:
            insights['risk_level'] = 'Medium'
            insights['forecast_insight'] = f"Caution: Your savings rate of {savings_rate:.1f}% is below recommended levels."
        else:
            insights['risk_level'] = 'Low'
            insights['forecast_insight'] = f"Positive: Your forecast shows a healthy savings rate of {savings_rate:.1f}%."

        # Analyze trends and provide context
        if income_trend < 0:
            insights['recommendations'].append({
                'category': 'Income',
                'priority': 'High',
                'action': "Your income is trending downward. Consider diversifying income sources or exploring career development opportunities.",
                'impact': "Critical for financial stability"
            })
        
        if expense_trend > income_trend:
            insights['recommendations'].append({
                'category': 'Expenses',
                'priority': 'High',
                'action': "Your expenses are growing faster than income. Review and optimize your monthly expenses.",
                'impact': "Essential for maintaining financial balance"
            })

        # Category-specific analysis
        if 'expense' in category_forecasts:
            high_growth_categories = find_high_growth_categories(category_forecasts['expense'])
            for category, growth in high_growth_categories:
                insights['recommendations'].append({
                    'category': 'Budget',
                    'priority': 'Medium',
                    'action': f"Your {category} expenses show {growth:.1f}% projected growth. Consider setting a budget cap.",
                    'impact': "Important for expense management"
                })

        # Goal achievement analysis
        if goal_projections:
            for goal in goal_projections:
                probability = goal['probability']
                monthly_required = goal['monthly_required']
                
                if probability < 50:
                    gap_amount = monthly_required - average_savings
                    insights['recommendations'].append({
                        'category': 'Goals',
                        'priority': 'High' if probability < 30 else 'Medium',
                        'action': f"Increase monthly savings by ${gap_amount:.2f} to stay on track for {goal['name']}.",
                        'impact': "Critical for goal achievement"
                    })

        # Identify opportunity areas
        if savings_rate > 20:
            insights['opportunity_areas'].append({
                'category': 'Investment',
                'description': "Consider diversifying investments with excess savings",
                'potential_impact': "Long-term wealth building"
            })
        
        if any(cat['amount'] > average_expenses * 0.3 for cat in find_top_categories(category_forecasts['expense'])):
            insights['opportunity_areas'].append({
                'category': 'Cost Optimization',
                'description': "Large expense categories identified - potential for significant savings",
                'potential_impact': "Immediate improvement in savings rate"
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
    forecast_months: int = Query(default=6, ge=1, le=24)
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
        insights = generate_insights_and_recommendations(forecast_data)
        
        # Add insights to the response
        forecast_data.update(insights)
        
        return forecast_data

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
