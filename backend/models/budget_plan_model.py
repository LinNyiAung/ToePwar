from pydantic import BaseModel
from typing import Dict, List, Literal, Optional
from datetime import datetime

class BudgetPlan(BaseModel):
    user_id: str
    period_type: Literal['daily', 'monthly', 'yearly']
    start_date: datetime
    end_date: datetime
    total_budget: float
    category_budgets: Dict[str, float]
    recommendations: List[str]
    savings_target: float
    created_at: datetime = datetime.utcnow()