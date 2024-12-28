from io import BytesIO
from fastapi import APIRouter, HTTPException, Query, Depends
from fastapi.responses import StreamingResponse
from database import transactions_collection, goals_collection
from utils import create_financial_report_excel, get_current_user
from datetime import datetime, timedelta
from typing import Optional

router = APIRouter()

@router.get("/financial-report")
def get_financial_report(
    user_id: str = Depends(get_current_user),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None)
):
    # If no end date specified, use current date
    if not end_date:
        end = datetime.now()
    else:
        end = datetime.fromisoformat(end_date)
    
   # If no start date specified, get the date of first transaction
    if not start_date:
        first_transaction = transactions_collection.find_one(
            {"user_id": user_id},
            sort=[("date", 1)]  # Sort by date ascending
        )
        start = first_transaction["date"] if first_transaction else end - timedelta(days=30)
    else:
        start = datetime.fromisoformat(start_date)
    
    # Create match condition for the date range
    match_condition = {
        "user_id": user_id,
        "date": {
            "$gte": start,
            "$lte": end
        }
    }

    # Use aggregation pipeline to calculate totals
    pipeline = [
        {"$match": match_condition},
        {
            "$group": {
                "_id": "$type",
                "total": {"$sum": {"$toDouble": "$amount"}}
            }
        }
    ]
    
    results = list(transactions_collection.aggregate(pipeline))
    
    # Initialize totals
    income_total = 0.0
    expense_total = 0.0
    
    # Process results
    for result in results:
        if result["_id"] == "income":
            income_total = result["total"]
        elif result["_id"] == "expense":
            expense_total = result["total"]
    
    net_income = income_total - expense_total
    
    # Calculate category breakdowns using aggregation
    income_pipeline = [
        {
            "$match": {
                **match_condition,
                "type": "income"
            }
        },
        {
            "$group": {
                "_id": "$category",
                "amount": {"$sum": {"$toDouble": "$amount"}}
            }
        },
        {
            "$project": {
                "category": "$_id",
                "amount": 1,
                "_id": 0
            }
        }
    ]
    
    expense_pipeline = [
        {
            "$match": {
                **match_condition,
                "type": "expense"
            }
        },
        {
            "$group": {
                "_id": "$category",
                "amount": {"$sum": {"$toDouble": "$amount"}}
            }
        },
        {
            "$project": {
                "category": "$_id",
                "amount": 1,
                "_id": 0
            }
        }
    ]
    
    income_by_category = list(transactions_collection.aggregate(income_pipeline))
    expense_by_category = list(transactions_collection.aggregate(expense_pipeline))
    
    # Get goals progress
    goals = goals_collection.find({
        "user_id": user_id,
        "$or": [
            {"deadline": {"$gte": start, "$lte": end}},
            {"completion_date": {"$gte": start, "$lte": end}}
        ]
    })
    
    goals_summary = []
    for goal in goals:
        target_amount = float(goal["target_amount"])
        current_amount = float(goal["current_amount"])
        progress = (current_amount / target_amount * 100) if target_amount > 0 else 0.0
        
        goals_summary.append({
            "name": goal["name"],
            "target_amount": target_amount,
            "current_amount": current_amount,
            "progress": progress,
            "completed": goal.get("completed", False),
            "completion_date": goal.get("completion_date")
        })
    
    # Calculate savings rate
    savings_rate = (net_income / income_total * 100) if income_total > 0 else 0.0
    
    return {
        "summary": {
            "period_start": start.isoformat(),
            "period_end": end.isoformat(),
            "total_income": income_total,
            "total_expense": expense_total,
            "net_income": net_income,
            "savings_rate": savings_rate
        },
        "income_by_category": income_by_category,
        "expense_by_category": expense_by_category,
        "goals_summary": goals_summary
    }


@router.get("/export-financial-report")
async def export_financial_report(
    user_id: str = Depends(get_current_user),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None)
):
    # Get the financial report data using the existing function
    report_data = get_financial_report(user_id, start_date, end_date)
    
    # Create Excel workbook
    wb = create_financial_report_excel(report_data)
    
    # Save to bytes buffer
    buffer = BytesIO()
    wb.save(buffer)
    buffer.seek(0)
    
    # Generate filename with current timestamp
    filename = f"financial_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.xlsx"
    
    # Return the Excel file as a downloadable response
    return StreamingResponse(
        buffer,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={
            "Content-Disposition": f"attachment; filename={filename}"
        }
    )
