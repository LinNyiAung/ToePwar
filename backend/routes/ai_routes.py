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
        'recommendations': []
    }
    
    try:
        # Extract forecast components
        income_forecast = forecast_data['income_forecast']
        expense_forecast = forecast_data['expense_forecast']
        savings_forecast = forecast_data['savings_forecast']
        category_forecasts = forecast_data['category_forecasts']
        goal_projections = forecast_data['goal_projections']

        # Calculate averages
        average_income = sum(f['amount'] for f in income_forecast) / len(income_forecast)
        average_expenses = sum(f['amount'] for f in expense_forecast) / len(expense_forecast)
        average_savings = sum(f['amount'] for f in savings_forecast) / len(savings_forecast)

        # Generate main insight based on financial health
        if average_income < average_expenses:
            insights['forecast_insight'] = "Warning: Your projected expenses are higher than your income."
            insights['recommendations'].append("Consider reducing expenses or finding additional income sources.")
        elif average_savings < 0:
            insights['forecast_insight'] = "Critical: Your forecast shows negative savings."
            insights['recommendations'].append("Urgently review and cut non-essential expenses.")
            insights['recommendations'].append("Explore ways to increase your income.")
        else:
            insights['forecast_insight'] = "Good Outlook: Your income is projected to cover expenses with potential savings."

        # Goal-based recommendations
        if goal_projections:
            for goal in goal_projections:
                probability = goal['probability']
                if probability < 50:
                    insights['recommendations'].append(
                        f"Goal Alert: {goal['name']} has low probability of completion. Consider adjusting your savings strategy."
                    )

        # Expense category analysis
        if 'expense' in category_forecasts:
            top_expense = find_top_category(category_forecasts['expense'])
            if top_expense:
                insights['recommendations'].append(
                    f"Top Expense Category: Focus on reducing {top_expense['category']} expenses."
                )

        # Savings rate analysis
        savings_rate = (average_savings / average_income) * 100 if average_income > 0 else 0
        if savings_rate < 10:
            insights['recommendations'].append(
                "Savings Tip: Aim to increase your savings rate. Currently, you're saving less than 10% of income."
            )
        elif savings_rate >= 10 and savings_rate < 20:
            insights['recommendations'].append(
                "Savings Progress: Good job! You're saving between 10-20% of your income."
            )
        else:
            insights['recommendations'].append(
                "Savings Champion: Excellent! You're saving over 20% of your income."
            )

    except Exception as e:
        insights['forecast_insight'] = "Unable to generate detailed insights at this time."
        insights['recommendations'].append("Please ensure your financial data is up to date.")

    return insights

def find_top_category(categories: dict) -> dict:
    if not categories:
        return None
    
    # Find category with highest amount in the latest forecast
    top_category = max(
        categories.items(),
        key=lambda x: x[1][-1]['amount'] if x[1] else 0
    )
    
    return {
        'category': top_category[0],
        'amount': top_category[1][-1]['amount'] if top_category[1] else 0
    }


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
