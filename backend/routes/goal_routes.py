from fastapi import APIRouter, HTTPException, Depends
from database import goals_collection
from models.goal_model import Goal
from utils import get_current_user
from bson import ObjectId
from bson.errors import InvalidId

router = APIRouter()

@router.post("/goal")
def set_goal(goal: Goal, user_id: str = Depends(get_current_user)):
    goal_data = goal.dict()
    goal_data["user_id"] = user_id
    result = goals_collection.insert_one(goal_data)
    created_goal = goals_collection.find_one({"_id": result.inserted_id})
    created_goal["_id"] = str(created_goal["_id"])
    return created_goal

@router.get("/goals")
def get_goals(user_id: str = Depends(get_current_user)):
    goals = goals_collection.find({"user_id": user_id})
    goals_list = []
    for goal in goals:
        goal["_id"] = str(goal["_id"])
        goals_list.append(goal)
    return {"goals": goals_list}


@router.delete("/deletegoals/{goal_id}")
def delete_goal(goal_id: str, user_id: str = Depends(get_current_user)):
    try:
        goal_object_id = ObjectId(goal_id)
        result = goals_collection.delete_one({
            "_id": goal_object_id,
            "user_id": user_id
        })
        
        if result.deleted_count == 0:
            raise HTTPException(
                status_code=404,
                detail="Goal not found or unauthorized"
            )
            
        return {"message": "Goal deleted successfully"}
        
    except InvalidId:
        raise HTTPException(
            status_code=400,
            detail="Invalid goal ID format"
        )
    


@router.put("/editgoals/{goal_id}")
def update_goal(
    goal_id: str,
    goal: Goal,
    user_id: str = Depends(get_current_user)
):
    try:
        goal_object_id = ObjectId(goal_id)
        
        # Verify the goal exists and belongs to the user
        existing_goal = goals_collection.find_one({
            "_id": goal_object_id,
            "user_id": user_id
        })
        
        if not existing_goal:
            raise HTTPException(
                status_code=404,
                detail="Goal not found or unauthorized"
            )
            
        # Preserve the current_amount and completion status
        update_data = goal.dict()
        update_data["user_id"] = user_id
        update_data["current_amount"] = existing_goal["current_amount"]
        update_data["completed"] = existing_goal["completed"]
        update_data["completion_date"] = existing_goal.get("completion_date")
        
        result = goals_collection.update_one(
            {"_id": goal_object_id, "user_id": user_id},
            {"$set": update_data}
        )
        
        if result.modified_count == 0:
            raise HTTPException(
                status_code=400,
                detail="Goal update failed"
            )
            
        updated_goal = goals_collection.find_one({"_id": goal_object_id})
        updated_goal["_id"] = str(updated_goal["_id"])
        return updated_goal
        
    except InvalidId:
        raise HTTPException(
            status_code=400,
            detail="Invalid goal ID format"
        )
