import io
import os
import json
import PIL.Image
import google.generativeai as genai
import logging
from fastapi import FastAPI, HTTPException, Depends, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from typing import Optional
from sqlalchemy.orm import Session
from database import engine, Base, SessionLocal, DBVital, DBBloodPressure, DBSleepSession, DBUser

# Load environment variables from .env file
load_dotenv()

# Import Pydantic models (The API Contract)
from models import (
    SymptomPayload,
    UserVitalsPayload,
    ClinicalAssessment,
    HealthScore,
    HealthSyncPayload,
)

# Import Core Logic Services
from medical_ai_service import MedicalAIService
from health_score_calculator import HealthScoreCalculator

# 1. Setup Logging for debugging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 2. Initialize FastAPI App
app = FastAPI(
    title="NirogX API",
    description="AI-powered health analysis and scoring API for the NirogX app.",
    version="1.0.0",
    docs_url="/docs", # The Swagger UI your team will use
)

# Create database tables if they don't exist
Base.metadata.create_all(bind=engine)

# Database Dependency Injection
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 3. Add CORS Middleware (Crucial for Flutter integration)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Replace "*" with specific domains in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 4. Dependency Injection for Services (Makes testing much easier)
def get_medical_ai_service():
    return MedicalAIService()

def get_health_score_calculator():
    return HealthScoreCalculator()

# --- Endpoints ---

@app.get("/", tags=["System"])
async def read_root():
    """Health check endpoint to verify the API is running."""
    return {"status": "online", "message": "Welcome to the NirogX API"}

@app.post(
    "/api/v1/analyze", 
    response_model=ClinicalAssessment, 
    tags=["Analysis"],
    summary="Analyze patient symptoms"
)
async def analyze_symptoms_endpoint(
    payload: SymptomPayload,
    ai_service: MedicalAIService = Depends(get_medical_ai_service),
    db: Session = Depends(get_db) # Inject the DB here
):
    """
    Accepts user symptoms and returns a preliminary clinical assessment.
    """
    logger.info(f"Received symptom analysis request for user: {getattr(payload, 'user_id', 'unknown')}")
    
    try:
        # Pass the db session into the service
        result = ai_service.analyze_symptoms(payload, db)
        return result
        
    except ValueError as ve:
        logger.warning(f"Validation Error: {str(ve)}")
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        logger.error(f"Unexpected error in symptom analysis: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error during analysis.")

@app.post(
    "/api/v1/health-score", 
    response_model=HealthScore, 
    tags=["Scoring"],
    summary="Calculate overall health score"
)
async def calculate_health_score_endpoint(
    payload: UserVitalsPayload,
    score_calculator: HealthScoreCalculator = Depends(get_health_score_calculator)
):
    """
    Calculates a health score based on user vitals and lifestyle.
    """
    logger.info(f"Received health score calculation request.")
    
    try:
        result = score_calculator.calculate_full_profile(payload)
        return HealthScore(**result)
        
    except ValueError as ve:
        logger.warning(f"Invalid vitals payload: {str(ve)}")
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        logger.error(f"Unexpected error calculating health score: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error during scoring.")

@app.post("/api/vitals/sync", tags=["Sync"])
async def sync_vitals_endpoint(
    payload: HealthSyncPayload,
    db: Session = Depends(get_db) # Inject the DB session
):
    """
    Receives synchronized health data from Flutter and stores it in SQLite.
    """
    logger.info(f"Received health sync payload from {payload.device_os} at {payload.sync_timestamp}")
    
    try:
        # Note: In a production app, you would extract the user_id from a JWT token here.
        # For now, we are ensuring a dummy user exists for testing.
        test_user = db.query(DBUser).filter(DBUser.id == 1).first()
        if not test_user:
            test_user = DBUser(id=1, email="test@nirogx.com")
            db.add(test_user)
            db.commit()

        # 1. Prepare Standard Vitals
        db_vitals = [
            DBVital(
                user_id=1,
                type=vital.type,
                value=vital.value,
                unit=vital.unit,
                recorded_at=vital.recorded_at.replace(tzinfo=None) # SQLite doesn't natively support tzinfo
            ) for vital in payload.vitals
        ]
        
        # 2. Prepare Blood Pressure
        db_bp = [
            DBBloodPressure(
                user_id=1,
                systolic=bp.systolic,
                diastolic=bp.diastolic,
                recorded_at=bp.recorded_at.replace(tzinfo=None)
            ) for bp in payload.blood_pressure
        ]
        
        # 3. Prepare Sleep Sessions
        db_sleep = [
            DBSleepSession(
                user_id=1,
                stage=sleep.stage,
                duration_minutes=sleep.duration_minutes,
                start_time=sleep.start_time.replace(tzinfo=None),
                end_time=sleep.end_time.replace(tzinfo=None)
            ) for sleep in payload.sleep_sessions
        ]

        # Use bulk operations for performance
        db.add_all(db_vitals)
        db.add_all(db_bp)
        db.add_all(db_sleep)
        db.commit() # Save everything in one transaction

        total_records = len(db_vitals) + len(db_bp) + len(db_sleep)
        logger.info(f"Successfully saved {total_records} records to SQLite database.")
        
        return {
            "status": "success",
            "message": f"Successfully processed and saved {total_records} data points.",
            "timestamp": payload.sync_timestamp
        }
        
    except Exception as e:
        db.rollback() # Cancel the transaction if anything goes wrong
        logger.error(f"Error processing health sync: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error during data sync.")

@app.post("/api/v1/chat", tags=["AI Chat"])
async def chat_endpoint(
    prompt: str = Form(...),
    user_id: int = Form(...),
    history: str = Form("[]"), # <-- NEW: Receive history as a JSON string
    image: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db)
):
    """
    RAG-enabled AI Chat with Conversation History memory.
    """
    logger.info(f"Chat request from user {user_id}. Image attached: {image is not None}")
    
    try:
        # 1. Parse the incoming history from Flutter
        parsed_history = json.loads(history)
        gemini_history = []
        for msg in parsed_history:
            # Gemini strictly expects "user" or "model" roles
            role = "user" if msg["role"] == "user" else "model"
            gemini_history.append({"role": role, "parts": [msg["text"]]})

        # 2. RETRIEVAL: Get context from SQLite
        recent_vitals = db.query(DBVital).filter(DBVital.user_id == user_id).order_by(DBVital.recorded_at.desc()).limit(5).all()
        if recent_vitals:
            vitals_text = "\n".join([f"- {v.type}: {v.value} {v.unit} (recorded at {v.recorded_at})" for v in recent_vitals])
            context_block = f"\n\n[SYSTEM CONTEXT - DO NOT MENTION UNLESS RELEVANT]\nUSER's RECENT DATABASE VITALS:\n{vitals_text}"
        else:
            context_block = "\n\n[SYSTEM CONTEXT]\nUSER's RECENT DATABASE VITALS: No recent data synced."

        # 3. Initialize Model
        system_instruction = (
            "You are NirogX, a clinical AI assistant. "
            "Answer the user's question directly and concisely. "
            "Use the provided database vitals to personalize your answer if they are relevant to the question. "
            "Always include a brief disclaimer that you are an AI, not a doctor."
        )

        apiKey = os.environ.get("GEMINI_API_KEY") 
        genai.configure(api_key=apiKey)

        model = genai.GenerativeModel(
            model_name="gemini-2.5-flash",
            system_instruction=system_instruction
        )

        # 4. GENERATION: Start a Chat Session with Memory
        chat_session = model.start_chat(history=gemini_history)
        
        # Combine the user's prompt with our invisible system context
        augmented_prompt = prompt + context_block

        if image:
            image_bytes = await image.read()
            pil_image = PIL.Image.open(io.BytesIO(image_bytes))
            # Send message to the active chat session
            response = chat_session.send_message([augmented_prompt, pil_image])
        else:
            response = chat_session.send_message(augmented_prompt)

        return {"status": "success", "response": response.text}

    except Exception as e:
        logger.error(f"Chat Error: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to generate AI response.")