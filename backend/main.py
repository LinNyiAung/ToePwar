from fastapi import FastAPI, Depends, HTTPException
from routes import auth_routes, budget_plan_routes, user_routes, transaction_routes, goal_routes, dashboard_routes, report_routes, ai_routes, chart_routes

app = FastAPI()


app.include_router(auth_routes.router, tags=["Authentication"])
app.include_router(user_routes.router, tags=["User"])
app.include_router(transaction_routes.router, tags=["Transactions"])
app.include_router(goal_routes.router, tags=["Goals"])
app.include_router(dashboard_routes.router, tags=["Dashboard"])
app.include_router(report_routes.router, tags=["Reports"])
app.include_router(ai_routes.router, tags=["AI"])
app.include_router(budget_plan_routes.router, tags=["Budget Plan"])
app.include_router(chart_routes.router, tags=["Charts"])






    











