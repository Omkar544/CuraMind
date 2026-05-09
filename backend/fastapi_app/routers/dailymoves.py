import os
import joblib
import pandas as pd
import uuid
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime, timezone
from ..services.mongo_storage import MongoStorage

router = APIRouter()

# --- Pydantic Model for DailyMoves Input ---
class DailyMovesInput(BaseModel):
    user_id: str
    
    steps: Optional[int] = 0
    calories: Optional[float] = 0.0
    
    age: int
    gender: str
    height_cm: float
    weight_kg: float
    activity_type: str
    duration_minutes: int
    intensity: str
    sleep_hours: float
    stress_level: int
    hydration_level: int
    smoking_status: str

# --- Model Loading ---
MODELS_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "ml_models", "dailymoves_model")

classifier = None
scaler_clf = None
label_encoders = None

try:
    classifier = joblib.load(os.path.join(MODELS_DIR, "fitness_classifier_tuned.pkl"))
    scaler_clf = joblib.load(os.path.join(MODELS_DIR, "scaler_clf_tuned.pkl"))
    label_encoders = joblib.load(os.path.join(MODELS_DIR, "label_encoders.pkl"))
    print("✅ DailyMoves: ML models (XGBoost) loaded successfully.")
except Exception as e:
    print(f"⚠️ Warning: Error loading DailyMoves models: {e}. Check path: {MODELS_DIR}")

# --- Predict Endpoint ---
@router.post("/predict")
async def predict_and_store(data: DailyMovesInput):

    if classifier is None or scaler_clf is None or label_encoders is None:
        raise HTTPException(
            status_code=500, 
            detail="Machine learning models are not initialized on the server."
        )

    try:
        # BMI Calculation
        height_meters = data.height_cm / 100
        if height_meters <= 0 or data.weight_kg <= 0:
            raise HTTPException(status_code=400, detail="Invalid biometric data provided.")
        
        calculated_bmi = round(data.weight_kg / (height_meters * height_meters), 2)

        input_dict = data.dict()
        input_dict['bmi'] = calculated_bmi
        
        input_df = pd.DataFrame([input_dict])

        categorical_cols = ["gender", "activity_type", "intensity", "smoking_status"]

        for col in categorical_cols:
            if col in label_encoders:
                val = str(input_df[col].iloc[0]).lower().strip()
                try:
                    input_df[col] = label_encoders[col].transform([val])
                except Exception:
                    input_df[col] = 0 

        selected_features = [
            "age", "gender", "height_cm", "weight_kg", "bmi",
            "activity_type", "duration_minutes", "intensity",
            "sleep_hours", "stress_level", "hydration_level", "smoking_status"
        ]
        
        input_df = input_df[selected_features]

        X_scaled = scaler_clf.transform(input_df)
        prediction_encoded = classifier.predict(X_scaled)[0]

        original_labels = ['At-Risk', 'Fit', 'Unfit']
        status_map = {
            'At-Risk': 'Attention Required',
            'Fit': 'Optimal Fitness',
            'Unfit': 'Moderate Activity'
        }

        try:
            raw_label = original_labels[int(prediction_encoded)]
            prediction_text = status_map.get(raw_label, "Logged")
        except (IndexError, ValueError):
            prediction_text = "Assessment Completed"

        # Save to Mongo (Mongo handles correct UTC timestamp)
        report_id = MongoStorage.save_report(
            user_id=data.user_id,
            module_name="Daily Moves",
            input_data=input_dict, 
            prediction=prediction_text
        )

        print(f"📊 DailyMoves: Assessment for {data.user_id} saved [Steps: {data.steps}]")

        return {
            "status": "success",
            "prediction": prediction_text,
            "lifelog_id": report_id,
            "bmi": calculated_bmi,
            # ✅ FIXED → timezone-aware UTC
            "timestamp": datetime.now(timezone.utc).isoformat()
        }

    except Exception as e:
        print(f"❌ DailyMoves Router Error: {e}")
        raise HTTPException(status_code=500, detail=f"AI Service Error: {str(e)}")

@router.get("/history/{user_id}")
async def get_moves_history(user_id: str):

    try:
        raw_history = MongoStorage.get_full_lifelog(user_id)
        
        moves_history = [
            item for item in raw_history.get("ai_reports", []) 
            if item.get("module") == "Daily Moves"
        ]
        
        for item in moves_history:
            item["_id"] = str(item["_id"])
            
        return {"history": moves_history}

    except Exception:
        raise HTTPException(status_code=500, detail="Failed to sync fitness history.")