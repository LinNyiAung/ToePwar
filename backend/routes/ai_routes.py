from fastapi import APIRouter, HTTPException, Query, Depends
from database import transactions_collection, goals_collection
from utils import get_current_user
from datetime import datetime, timedelta
from sklearn.linear_model import LinearRegression
import numpy as np
import pandas as pd

router = APIRouter()

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

        return {
            'income_forecast': income_forecast,
            'expense_forecast': expense_forecast,
            'savings_forecast': savings_forecast,
            'category_forecasts': category_forecasts,
            'goal_projections': goal_projections
        }

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
