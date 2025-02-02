from bson import ObjectId
from pydantic import BaseModel, validator
from typing import Optional
from datetime import datetime

import pytz

class Goal(BaseModel):
    name: str
    target_amount: float
    current_amount: float = 0
    deadline: datetime
    completed: bool = False
    completion_date: Optional[datetime] = None
    user_id: Optional[str] = None

    @validator('deadline', pre=True)
    def parse_deadline(cls, value):
        utc = pytz.UTC
        if isinstance(value, str):
            # Remove milliseconds if present and handle timezone
            deadline_str = value.split('.')[0]
            if deadline_str.endswith('Z'):
                deadline_str = deadline_str[:-1] + '+00:00'
            deadline = datetime.fromisoformat(deadline_str)
            if deadline.tzinfo is None:
                deadline = utc.localize(deadline)
            return deadline
        elif isinstance(value, datetime):
            if value.tzinfo is None:
                return utc.localize(value)
            return value
        return value

    class Config:
        json_encoders = {
            ObjectId: str,
            datetime: lambda v: v.isoformat()
        }
