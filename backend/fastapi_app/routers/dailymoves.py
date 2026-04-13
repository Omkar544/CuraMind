import os
import joblib
import pandas as pd
import uuid
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime
from ..services.mongo_storage import MongoStorage

router = APIRouter()

# --- Pydantic Model for DailyMoves Input ---
class DailyMovesInput(BaseModel):
    user_id: str          # The UUID generated in PostgreSQL during registration
    
    # Fitbit/Activity Data (Captured from mobile for storage in LifeLog Hub)
    steps: Optional[int] = 0
    calories: Optional[float] = 0.0
    
    # ML Model Features (Strictly ordered for XGBoost)
    age: int
    gender: str
    height_cm: float
    weight_kg: float
    activity_type: str
    duration_minutes: int
    intensity: str        # Low, Moderate, High
    sleep_hours: float
    stress_level: int     # 1-10
    hydration_level: int  # ml or cups
    smoking_status: str

# --- Model Loading Logic ---
# Pointing to the absolute path relative to this router
MODELS_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "ml_models", "dailymoves_model")

classifier = None
scaler_clf = None
label_encoders = None

try:
    # Attempting to load the pre-trained XGBoost assets
    classifier = joblib.load(os.path.join(MODELS_DIR, "fitness_classifier_tuned.pkl"))
    scaler_clf = joblib.load(os.path.join(MODELS_DIR, "scaler_clf_tuned.pkl"))
    label_encoders = joblib.load(os.path.join(MODELS_DIR, "label_encoders.pkl"))
    print("✅ DailyMoves: ML models (XGBoost) loaded successfully.")
except Exception as e:
    print(f"⚠️ Warning: Error loading DailyMoves models: {e}. Check path: {MODELS_DIR}")

# --- Endpoints ---

@router.post("/predict")
async def predict_and_store(data: DailyMovesInput):
    """
    1. Receives health data from the mobile app (including Fitbit steps/calories).
    2. Calculates BMI for the assessment model.
    3. Runs the XGBoost Prediction.
    4. Saves the integrated health snapshot to MongoDB for the LifeLog Hub.
    """
    # Guard check to ensure models are available
    if classifier is None or scaler_clf is None or label_encoders is None:
        raise HTTPException(
            status_code=500, 
            detail="Machine learning models are not initialized on the server."
        )

    try:
        # --- STEP 1: BMI Calculation ---
        # Formula: kg / m^2
        height_meters = data.height_cm / 100
        if height_meters <= 0 or data.weight_kg <= 0:
            raise HTTPException(status_code=400, detail="Invalid biometric data provided.")
        
        calculated_bmi = round(data.weight_kg / (height_meters * height_meters), 2)

        # --- STEP 2: Data Preparation for ML ---
        # Convert input to dictionary for processing
        input_dict = data.dict()
        
        # Inject the calculated BMI for the model
        input_dict['bmi'] = calculated_bmi
        
        # Create DataFrame for prediction
        input_df = pd.DataFrame([input_dict])

        # Categorical encoding (Standardizing strings from mobile to model-readable integers)
        categorical_cols = ["gender", "activity_type", "intensity", "smoking_status"]

        for col in categorical_cols:
            if col in label_encoders:
                # Normalize text to lowercase/trimmed to match training data
                val = str(input_df[col].iloc[0]).lower().strip()
                try:
                    input_df[col] = label_encoders[col].transform([val])
                except Exception:
                    # Fallback for unseen categories (e.g., 'other' or typos)
                    input_df[col] = 0 

        # IMPORTANT: Feature order MUST match the XGBoost training order exactly
        selected_features = [
            "age", "gender", "height_cm", "weight_kg", "bmi",
            "activity_type", "duration_minutes", "intensity",
            "sleep_hours", "stress_level", "hydration_level", "smoking_status"
        ]
        
        # Reorder columns to match scaler expectation
        input_df = input_df[selected_features]

        # --- STEP 3: Prediction & Result Mapping ---
        X_scaled = scaler_clf.transform(input_df)
        prediction_encoded = classifier.predict(X_scaled)[0]

        # Map integer predictions to user-friendly status labels
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

        # --- STEP 4: SAVE INTEGRATED SNAPSHOT TO MONGODB ---
        # We include steps and calories in the 'inputs' so they show up in the LifeLog Hub
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
            "timestamp": datetime.utcnow().isoformat()
        }

    except Exception as e:
        print(f"❌ DailyMoves Router Error: {e}")
        raise HTTPException(status_code=500, detail=f"AI Service Error: {str(e)}")

@router.get("/history/{user_id}")
async def get_moves_history(user_id: str):
    """
    Fetches user-specific fitness history from MongoDB.
    """
    try:
        raw_history = MongoStorage.get_full_lifelog(user_id)
        
        # Filter for only fitness assessments
        moves_history = [
            item for item in raw_history.get("ai_reports", []) 
            if item.get("module") == "Daily Moves"
        ]
        
        # Convert IDs for JSON
        for item in moves_history:
            item["_id"] = str(item["_id"])
            
        return {"history": moves_history}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to sync fitness history.")