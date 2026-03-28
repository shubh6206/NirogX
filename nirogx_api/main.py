import io
import os
import json
import jwt
import PIL.Image
import google.generativeai as genai
import logging
from passlib.context import CryptContext
from datetime import datetime, timedelta
from fastapi import FastAPI, HTTPException, Depends, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from typing import Optional
from sqlalchemy.orm import Session
from database import engine, Base, SessionLocal, DBVital, DBBloodPressure, DBSleepSession, DBUser, DBChatMessage, DBMedicalHistory, DBUserGoal

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

from pydantic import BaseModel

# --- 1. Pydantic Schemas for incoming manual data ---
class ManualVitalPayload(BaseModel):
    user_id: int = 1
    type: str
    value: float
    unit: str

class MedicalHistoryPayload(BaseModel):
    user_id: int = 1
    condition: str

class UserGoalPayload(BaseModel):
    user_id: int = 1
    goal_type: str
    target_value: float

# --- Auth Pydantic Models ---
class UserSignup(BaseModel):
    name: str
    email: str
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

# --- Security Config ---
SECRET_KEY = "your-super-secret-jwt-key" # Change this in production!
ALGORITHM = "HS256"
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

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

# --- Auth Endpoints ---
@app.post("/api/v1/auth/signup", tags=["Auth"])
async def signup(user: UserSignup, db: Session = Depends(get_db)):
    # Check if user exists
    existing_user = db.query(DBUser).filter(DBUser.email == user.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Hash password and save
    hashed_pw = pwd_context.hash(user.password)
    new_user = DBUser(name=user.name, email=user.email, hashed_password=hashed_pw)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # Generate Token
    token_data = {"sub": str(new_user.id), "exp": datetime.utcnow() + timedelta(days=30)}
    token = jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)
    
    return {"token": token, "user_id": new_user.id, "name": new_user.name}

@app.post("/api/v1/auth/login", tags=["Auth"])
async def login(user: UserLogin, db: Session = Depends(get_db)):
    db_user = db.query(DBUser).filter(DBUser.email == user.email).first()
    
    if not db_user or not pwd_context.verify(user.password, db_user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    
    # Generate Token
    token_data = {"sub": str(db_user.id), "exp": datetime.utcnow() + timedelta(days=30)}
    token = jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)
    
    return {"token": token, "user_id": db_user.id, "name": db_user.name}

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

@app.post("/api/v1/profile/medical-history", tags=["Profile"])
async def add_medical_history(payload: MedicalHistoryPayload, db: Session = Depends(get_db)):
    new_condition = DBMedicalHistory(user_id=payload.user_id, condition=payload.condition)
    db.add(new_condition)
    db.commit()
    return {"status": "success", "message": "Medical history added."}

@app.post("/api/v1/profile/goals", tags=["Profile"])
async def update_user_goal(payload: UserGoalPayload, db: Session = Depends(get_db)):
    # Check if goal exists to update, or create new
    existing_goal = db.query(DBUserGoal).filter(DBUserGoal.user_id == payload.user_id, DBUserGoal.goal_type == payload.goal_type).first()
    if existing_goal:
        existing_goal.target_value = payload.target_value
    else:
        new_goal = DBUserGoal(user_id=payload.user_id, goal_type=payload.goal_type, target_value=payload.target_value)
        db.add(new_goal)
    db.commit()
    return {"status": "success"}

@app.post("/api/v1/vitals/manual", tags=["Vitals"])
async def log_manual_vital(payload: ManualVitalPayload, db: Session = Depends(get_db)):
    new_vital = DBVital(user_id=payload.user_id, type=payload.type, value=payload.value, unit=payload.unit, recorded_at=datetime.utcnow())
    db.add(new_vital)
    db.commit()
    return {"status": "success"}

@app.post("/api/v1/chat", tags=["AI Chat"])
async def chat_endpoint(
    prompt: str = Form(...),
    user_id: int = Form(...),
    session_id: str = Form(...), # <-- NEW: We use this instead of the raw history array
    image: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db)
):
    """
    RAG-enabled AI Chat with Database-Backed long-term memory.
    """
    logger.info(f"Chat request from user {user_id}, session {session_id}. Image: {image is not None}")
    
    try:
        # 1. Save the USER'S message to SQLite immediately
        user_msg = DBChatMessage(user_id=user_id, session_id=session_id, role="user", text=prompt)
        db.add(user_msg)
        db.commit()

        # 2. Fetch the past history for THIS specific session from SQLite
        past_messages = db.query(DBChatMessage).filter(
            DBChatMessage.session_id == session_id
        ).order_by(DBChatMessage.timestamp.asc()).all()

        gemini_history = []
        for msg in past_messages:
            # Skip the message we literally just saved above so we don't duplicate it in the prompt
            if msg.id != user_msg.id: 
                gemini_history.append({"role": msg.role, "parts": [msg.text]})

        # 3. AUGMENTATION: Get context from SQLite (RAG)
        # Get Vitals
        recent_vitals = db.query(DBVital).filter(DBVital.user_id == user_id).order_by(DBVital.recorded_at.desc()).limit(5).all()
        vitals_text = "\n".join([f"- {v.type}: {v.value} {v.unit} (recorded at {v.recorded_at})" for v in recent_vitals]) if recent_vitals else "None reported"
        
        # Get Medical History
        med_history = db.query(DBMedicalHistory).filter(DBMedicalHistory.user_id == user_id).all()
        med_text = ", ".join([m.condition for m in med_history]) if med_history else "None reported"

        # Get Active Goals
        goals = db.query(DBUserGoal).filter(DBUserGoal.user_id == user_id).all()
        goals_text = ", ".join([f"{g.goal_type}: {g.target_value}" for g in goals]) if goals else "None set"

        # Construct the Ultimate RAG Context Block
        context_block = f"""
\n\n[SYSTEM CONTEXT - USE THIS TO PERSONALIZE ANSWERS]
USER VITALS: {vitals_text}
KNOWN MEDICAL HISTORY: {med_text}
ACTIVE HEALTH GOALS: {goals_text}
"""

        # 4. Initialize Gemini
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

        # 5. GENERATION: Start a Chat Session with Memory
        chat_session = model.start_chat(history=gemini_history)
        augmented_prompt = prompt + context_block

        if image:
            image_bytes = await image.read()
            pil_image = PIL.Image.open(io.BytesIO(image_bytes))
            response = chat_session.send_message([augmented_prompt, pil_image])
        else:
            response = chat_session.send_message(augmented_prompt)

        # 6. Save the AI'S response to SQLite
        ai_msg = DBChatMessage(user_id=user_id, session_id=session_id, role="model", text=response.text)
        db.add(ai_msg)
        db.commit()

        return {"status": "success", "response": response.text}

    except Exception as e:
        db.rollback()
        logger.error(f"Chat Error: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to generate AI response.")

@app.get("/api/v1/chat/history/{user_id}", tags=["AI Chat"])
async def get_chat_history(user_id: int, db: Session = Depends(get_db)):
    """Fetches all unique chat sessions for a user, grouped by session_id"""
    try:
        messages = db.query(DBChatMessage).filter(DBChatMessage.user_id == user_id).order_by(DBChatMessage.timestamp.asc()).all()
        
        # Group messages by session_id
        sessions = {}
        for msg in messages:
            if msg.session_id not in sessions:
                sessions[msg.session_id] = []
            sessions[msg.session_id].append({
                "role": msg.role,
                "text": msg.text,
                "timestamp": msg.timestamp.isoformat()
            })
            
        return {"status": "success", "sessions": sessions}
    except Exception as e:
        logger.error(f"History Fetch Error: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to fetch chat history.")

@app.get("/api/v1/action-plan/{user_id}", tags=["AI Coach"])
async def get_action_plan(user_id: int, db: Session = Depends(get_db)):
    """
    Analyzes user vitals and chat history to generate 3 personalized daily goals.
    """
    try:
        # 1. RETRIEVE context
        recent_vitals = db.query(DBVital).filter(DBVital.user_id == user_id).order_by(DBVital.recorded_at.desc()).limit(10).all()
        recent_chats = db.query(DBChatMessage).filter(DBChatMessage.user_id == user_id).order_by(DBChatMessage.timestamp.desc()).limit(5).all()
        
        vitals_ctx = ", ".join([f"{v.type}: {v.value}" for v in recent_vitals])
        chat_ctx = " | ".join([f"{m.role}: {m.text[:50]}" for m in recent_chats])

        # 2. PROMPT Gemini
        prompt = f"""
        Analyze this user's health context:
        VITALS: {vitals_ctx}
        RECENT CHAT: {chat_ctx}

        Output a JSON array of EXACTLY 3 daily health goals.
        Use these fields: id (string), title (short), unit, iconName (droplets, moon, footprints, or pill), 
        color (hex string), currentValue (0), targetValue (number), isManual (boolean).
        Target values should be realistic. If hydration is needed, use 'L' and target 2.5.
        
        Output ONLY the JSON array. No other text.
        """

        apiKey = os.environ.get("GEMINI_API_KEY") 
        genai.configure(api_key=apiKey)
        model = genai.GenerativeModel("gemini-1.5-flash") # Use 1.5 flash for speed/JSON consistency
        
        response = model.generate_content(prompt)
        
        # Simple cleanup if Gemini adds markdown blocks
        clean_json = response.text.replace("```json", "").replace("```", "").strip()
        goals = json.loads(clean_json)

        return {"status": "success", "goals": goals}

    except Exception as e:
        # Fallback to default goals if AI fails
        return {
            "status": "fallback",
            "goals": [
                {"id": "f1", "title": "Hydration", "unit": "L", "iconName": "droplets", "color": "0xFF2196F3", "currentValue": 0.0, "targetValue": 2.0, "isManual": True},
                {"id": "f2", "title": "Daily Walk", "unit": "mins", "iconName": "footprints", "color": "0xFF4CAF50", "currentValue": 0.0, "targetValue": 30.0, "isManual": False},
                {"id": "f3", "title": "Sleep Prep", "unit": "Sessions", "iconName": "moon", "color": "0xFF3F51B5", "currentValue": 0.0, "targetValue": 1.0, "isManual": True}
            ]
        }
