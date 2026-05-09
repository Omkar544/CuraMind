from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from datetime import datetime, timezone
from ..services.mongo_storage import MongoStorage

router = APIRouter()
analyzer = SentimentIntensityAnalyzer()

# --- Pydantic Models ---

class JournalEntry(BaseModel):
    text: str

class SentimentResponse(BaseModel):
    mood: str
    sentiment_score: float
    suggestion: str
    detailed_analysis: dict

class MentalHealthAssessment(BaseModel):
    user_id: str
    phq_score: int
    phq_level: str
    gad_score: int
    gad_level: str
    journal_entry: str
    journal_sentiment: str  
    overall_suggestion: str
    journal_tip: str        

# --- Endpoints ---

@router.post("/analyze_sentiment", response_model=SentimentResponse)
async def analyze_journal_sentiment(entry: JournalEntry):

    if not entry.text.strip():
        raise HTTPException(status_code=400, detail="Journal entry cannot be empty.")

    vs = analyzer.polarity_scores(entry.text)
    compound_score = vs['compound']

    if compound_score >= 0.05:
        mood = "Positive 🌞"
        suggestion = "You seem to be in a good headspace! Reflect on what contributed to this positivity today."
    elif compound_score <= -0.05:
        mood = "Negative 🌧️"
        suggestion = "It sounds like things are tough right now. Remember to be kind to yourself and reach out if you need support."
    else:
        mood = "Neutral 🌤️"
        suggestion = "A balanced perspective is great. Is there anything specific on your mind today?"

    return SentimentResponse(
        mood=mood,
        sentiment_score=compound_score,
        suggestion=suggestion,
        detailed_analysis=vs
    )

@router.post("/save_assessment", status_code=status.HTTP_201_CREATED)
async def save_assessment_results(report: MentalHealthAssessment):

    try:
        # ✅ FIXED: Pass timezone-aware UTC timestamp
        report_id = MongoStorage.save_report(
            user_id=report.user_id,
            module_name="MindEase",
            input_data={
                "phq_score": report.phq_score,
                "phq_level": report.phq_level,
                "gad_score": report.gad_score,
                "gad_level": report.gad_level,
                "journal_entry": report.journal_entry,
                "journal_sentiment": report.journal_sentiment,
                "journal_tip": report.journal_tip
            },
            prediction=report.overall_suggestion,
            timestamp=datetime.now(timezone.utc)   # ✅ IMPORTANT FIX
        )
        
        print(f"✅ MindEase: Assessment for {report.user_id} saved to MongoDB.")
        
        return {
            "status": "success",
            "message": "Mental health check-in logged successfully.",
            "id": report_id,
            "timestamp": datetime.now(timezone.utc).isoformat()  # ✅ consistent return
        }

    except Exception as e:
        print(f"❌ MindEase Save Error: {e}")
        raise HTTPException(
            status_code=500, 
            detail=f"Failed to save assessment to LifeLog: {str(e)}"
        )