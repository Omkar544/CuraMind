from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
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
    user_id: str            # Linked to PostgreSQL UUID
    phq_score: int          # PHQ-9 Total
    phq_level: str          # e.g., "Mild depression"
    gad_score: int          # GAD-7 Total
    gad_level: str          # e.g., "Minimal anxiety"
    journal_entry: str
    journal_sentiment: str  
    overall_suggestion: str
    journal_tip: str        

# --- Endpoints ---

@router.post("/analyze_sentiment", response_model=SentimentResponse)
async def analyze_journal_sentiment(entry: JournalEntry):
    """
    Performs sentiment analysis on the journal text using VADER.
    Provides immediate feedback to the Flutter UI during the assessment.
    """
    if not entry.text.strip():
        raise HTTPException(status_code=400, detail="Journal entry cannot be empty.")

    # Get polarity scores
    vs = analyzer.polarity_scores(entry.text)
    compound_score = vs['compound']

    # Logic to determine mood label and helpful tip
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
    """
    Saves the complete mental health check-in (PHQ-9, GAD-7, and Journal) to MongoDB.
    This ensures the data is available in the LifeLog Hub timeline.
    """
    try:
        # We use the save_report method from MongoStorage to keep history consistent
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
            prediction=report.overall_suggestion
        )
        
        print(f"✅ MindEase: Assessment for {report.user_id} saved to MongoDB.")
        
        return {
            "status": "success",
            "message": "Mental health check-in logged successfully.",
            "id": report_id
        }
    except Exception as e:
        print(f"❌ MindEase Save Error: {e}")
        raise HTTPException(
            status_code=500, 
            detail=f"Failed to save assessment to LifeLog: {str(e)}"
        )