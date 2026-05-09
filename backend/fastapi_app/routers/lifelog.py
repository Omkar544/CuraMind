# lifelog.py

from fastapi import APIRouter, HTTPException, status, UploadFile, File, Form
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
import pytz
import fitz
from PIL import Image
import pytesseract
import io
import nltk

from sumy.summarizers.lsa import LsaSummarizer
from sumy.parsers.plaintext import PlaintextParser
from sumy.nlp.tokenizers import Tokenizer

from ..services.mongo_storage import MongoStorage

router = APIRouter()

nltk.download("punkt")

india = pytz.timezone("Asia/Kolkata")


# =========================================
# MODELS
# =========================================

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


# =========================================
# GET COMPLETE LIFELOG HISTORY
# =========================================

@router.get("/history/{user_id}")
async def get_user_history_hub(user_id: str):
    try:
        raw_data = MongoStorage.get_full_lifelog(user_id)

        def convert_to_ist(record):
            if "timestamp" in record:
                ts = record["timestamp"]

                if ts.tzinfo is None:
                    ts = pytz.utc.localize(ts)

                record["timestamp"] = ts.astimezone(india).strftime("%d-%m-%Y %I:%M %p IST")

            record["_id"] = str(record["_id"])
            return record

        daily_moves = []
        mind_ease = []
        digitized_records = []

        for report in raw_data.get("ai_reports", []):
            module = report.get("module")
            report = convert_to_ist(report)

            if module == "Daily Moves":
                daily_moves.append(report)
            elif module == "MindEase":
                mind_ease.append(report)
            elif module == "Vision Scan":
                digitized_records.append(report)

        meds = [convert_to_ist(m) for m in raw_data.get("medicine_alerts", [])]
        apps = [convert_to_ist(a) for a in raw_data.get("appointments", [])]

        return {
            "daily_moves": daily_moves,
            "mind_ease": mind_ease,
            "appointments": apps,
            "medicines": meds,
            "digitized_reports": digitized_records
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# =========================================
# PDF / IMAGE SUMMARIZER
# =========================================

@router.post("/summarize_document")
async def summarize_document(
    user_id: str = Form(...),
    file: UploadFile = File(...)
):
    try:
        contents = await file.read()
        extracted_text = ""

        if file.filename.lower().endswith(".pdf"):
            doc = fitz.open(stream=contents, filetype="pdf")

            for page in doc:
                text = page.get_text()

                if not text.strip():
                    pix = page.get_pixmap()
                    img = Image.open(io.BytesIO(pix.tobytes()))
                    text = pytesseract.image_to_string(img)

                extracted_text += text + "\n"

            doc.close()

        elif file.filename.lower().endswith((".jpg", ".jpeg", ".png")):
            image = Image.open(io.BytesIO(contents))
            extracted_text = pytesseract.image_to_string(image)

        else:
            return {"summary": "Unsupported file type."}

        if not extracted_text.strip():
            return {"summary": "No readable text found in document."}

        extracted_text = extracted_text[:5000]

        parser = PlaintextParser.from_string(extracted_text, Tokenizer("english"))
        summarizer = LsaSummarizer()
        summary_sentences = summarizer(parser.document, 5)
        summary = " ".join(str(sentence) for sentence in summary_sentences)

        if not summary.strip():
            summary = "Document analyzed but meaningful summary could not be generated."

        timestamp = datetime.now(india)

        MongoStorage.save_report(
            user_id=user_id,
            module_name="Vision Scan",
            input_data={"filename": file.filename},
            prediction=summary,
            timestamp=timestamp
        )

        return {
            "status": "success",
            "summary": summary,
            "timestamp": timestamp.strftime("%d-%m-%Y %I:%M %p IST")
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail="Document processing failed.")


# =========================================
# SAVE DAILY MOVES
# =========================================

@router.post("/fitness_report", status_code=status.HTTP_201_CREATED)
async def create_fitness_report(report: FitnessReport):
    try:
        timestamp = datetime.now(india)

        report_id = MongoStorage.save_report(
            user_id=report.user_id,
            module_name="Daily Moves",
            input_data=report.dict(exclude={"timestamp"}),
            prediction=report.prediction,
            timestamp=timestamp
        )

        return {"status": "success", "id": report_id}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# =========================================
# SAVE MINDEASE
# =========================================

@router.post("/mental_health_report", status_code=status.HTTP_201_CREATED)
async def create_mental_health_report(report: MentalHealthReport):
    try:
        timestamp = datetime.now(india)

        report_id = MongoStorage.save_report(
            user_id=report.user_id,
            module_name="MindEase",
            input_data=report.dict(exclude={"timestamp"}),
            prediction=report.overall_suggestion,
            timestamp=timestamp
        )

        return {"status": "success", "id": report_id}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))