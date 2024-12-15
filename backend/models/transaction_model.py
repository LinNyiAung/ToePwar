from bson import ObjectId
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class Transaction(BaseModel):
    type: str  # income or expense
    amount: float
    category: str  # e.g., food, transport
    date: datetime
    user_id: Optional[str] = None

    class Config:
        json_encoders = {
            ObjectId: str  # Convert ObjectId to string
        }
