from bson import ObjectId
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class Goal(BaseModel):
    name: str
    target_amount: float
    current_amount: float = 0
    deadline: datetime
    completed: bool = False
    completion_date: Optional[datetime] = None
    user_id: Optional[str] = None

    class Config:
        json_encoders = {
            ObjectId: str
        }
