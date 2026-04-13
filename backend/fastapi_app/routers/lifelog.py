from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from ..services.mongo_storage import MongoStorage

router = APIRouter()

# --- Pydantic Models for Validation ---

class FitnessReport(BaseModel):
    user_id: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    gender: str
    age: int
    height_cm: float
    weight_kg: float
    activity_level: str
    workout_minutes_today: int
    calories_consumed_today: int
    sleep_hours_last_night: float
    water_liters_today: float
    stress_level: int
    prediction: str
    xai_explanation: Optional[str] = None

class MentalHealthReport(BaseModel):
    user_id: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    phq_score: int
    phq_level: str
    gad_score: int
    gad_level: str
    journal_entry: str
    journal_sentiment: str
    overall_suggestion: str
    journal_tip: Optional[str] = None

# --- LifeLog Hub Endpoints ---

@router.get("/history/{user_id}")
async def get_user_history_hub(user_id: str):
    """
    Aggregates all user activity from MongoDB.
    Categorizes data for the Flutter 'LifeLog Hub' timeline.
    """
    print(f"--- 📡 Syncing Integrated History for: {user_id} ---")
    try:
        # Fetch data from MongoStorage
        raw_data = MongoStorage.get_full_lifelog(user_id)
        
        daily_moves = []
        mind_ease = []
        digitized_records = [] # Added for Vision feature
        
        # 1. Process AI Module Reports
        for report in raw_data.get("ai_reports", []):
            report["_id"] = str(report["_id"]) 
            
            module_name = report.get("module")
            if module_name == "Daily Moves":
                daily_moves.append(report)
            elif module_name == "MindEase":
                mind_ease.append(report)
            elif module_name == "Vision Scan": # Support for stored digitized reports
                digitized_records.append(report)

        # 2. Process Medicine Reminders
        meds = raw_data.get("medicine_alerts", [])
        for m in meds:
            m["_id"] = str(m["_id"])
        
        # 3. Process Doctor Appointments
        apps = raw_data.get("appointments", [])
        for a in apps:
            a["_id"] = str(a["_id"])

        print(f"✅ Found {len(daily_moves)} Moves, {len(mind_ease)} Moods, {len(apps)} Apps, {len(meds)} Meds")

        return {
            "daily_moves": daily_moves,
            "mind_ease": mind_ease,
            "appointments": apps,
            "medicines": meds,
            "digitized_reports": digitized_records # Sending back to UI
        }
    except Exception as e:
        print(f"❌ LifeLog Router Error: {e}")
        raise HTTPException(
            status_code=500, 
            detail=f"History Sync Failed: {str(e)}"
        )

@router.post("/save_vision_report")
async def save_vision_report(data: dict):
    """Saves the Gemini Vision analysis so it persists after refresh."""
    try:
        report_id = MongoStorage.save_report(
            user_id=data['user_id'],
            module_name="Vision Scan",
            input_data={"filename": data.get('filename')},
            prediction=data.get('summary')
        )
        return {"status": "success", "id": report_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/fitness_report", status_code=status.HTTP_201_CREATED)
async def create_fitness_report(report: FitnessReport):
    try:
        report_id = MongoStorage.save_report(
            user_id=report.user_id,
            module_name="Daily Moves",
            input_data=report.dict(),
            prediction=report.prediction
        )
        return {"status": "success", "id": report_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/mental_health_report", status_code=status.HTTP_201_CREATED)
async def create_mental_health_report(report: MentalHealthReport):
    try:
        report_id = MongoStorage.save_report(
            user_id=report.user_id,
            module_name="MindEase",
            input_data=report.dict(),
            prediction=report.overall_suggestion
        )
        return {"status": "success", "id": report_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))