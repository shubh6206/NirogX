import os
import uuid
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional

from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext

from config import settings
from models import (
    UserCreate, UserLogin, UserResponse, Token,
    VitalLog, BloodPressureLog, VitalsPayload,
    HealthScoreResult, SymptomAnalysisRequest, SymptomAnalysisResponse,
    ChatRequest
)
from services.health_score_engine import calculate_deterministic_health_score
from services.gemini_service import analyze_symptoms_with_gemini, generate_chat_response_with_gemini

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="NirogX Clinical & Health Synchronization Backend API",
    version="1.0.0"
)

# CORS setup
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

# In-memory storage (production can bind to PostgreSQL / SQLite / Firestore)
USERS_DB: Dict[str, Dict[str, Any]] = {
    "user@example.com": {
        "id": "usr_default_001",
        "email": "user@example.com",
        "name": "Alex Mercer",
        "password_hash": pwd_context.hash("password123"),
        "age": 28,
        "gender": "Male",
        "height": 175.0,
        "weight": 70.0,
        "created_at": datetime.utcnow()
    }
}

VITALS_DB: List[Dict[str, Any]] = [
    {"id": "v1", "type": "heart_rate", "value": 68.0, "unit": "bpm", "source": "Galaxy Watch", "timestamp": datetime.utcnow().isoformat()},
    {"id": "v2", "type": "SpO2", "value": 98.5, "unit": "%", "source": "Health Connect", "timestamp": datetime.utcnow().isoformat()},
    {"id": "v3", "type": "steps", "value": 8421.0, "unit": "steps", "source": "Health Connect", "timestamp": datetime.utcnow().isoformat()},
    {"id": "v4", "type": "active_calories", "value": 486.0, "unit": "kcal", "source": "Apple HealthKit", "timestamp": datetime.utcnow().isoformat()}
]

BP_DB: List[Dict[str, Any]] = [
    {"id": "bp1", "systolic": 118, "diastolic": 78, "pulse": 68, "timestamp": datetime.utcnow().isoformat()}
]

MEDICAL_HISTORY_DB: List[str] = [
    "Seasonal Allergic Rhinitis",
    "Mild Asthmatic Bronchospasm (Controlled)"
]

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

async def get_current_user(token: str = Depends(oauth2_scheme)) -> UserResponse:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        email: str = payload.get("sub")
        if email is None or email not in USERS_DB:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user_dict = USERS_DB[email]
    return UserResponse(
        id=user_dict["id"],
        email=user_dict["email"],
        name=user_dict["name"],
        age=user_dict.get("age", 28),
        gender=user_dict.get("gender", "Male"),
        height=user_dict.get("height", 175.0),
        weight=user_dict.get("weight", 70.0),
        created_at=user_dict.get("created_at", datetime.utcnow())
    )

# --- Routes ---

@app.get("/api/health")
async def health_check():
    return {
        "status": "online",
        "service": "NirogX Clinical AI Backend",
        "version": "1.0.0",
        "timestamp": datetime.utcnow().isoformat()
    }

# 1. Authentication
@app.post("/api/auth/register", response_model=Token)
async def register(user: UserCreate):
    if user.email in USERS_DB:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    user_id = f"usr_{uuid.uuid4().hex[:8]}"
    USERS_DB[user.email] = {
        "id": user_id,
        "email": user.email,
        "name": user.name,
        "password_hash": pwd_context.hash(user.password),
        "age": user.age,
        "gender": user.gender,
        "height": user.height,
        "weight": user.weight,
        "created_at": datetime.utcnow()
    }
    
    token = create_access_token({"sub": user.email})
    return Token(
        access_token=token,
        token_type="bearer",
        user=UserResponse(
            id=user_id,
            email=user.email,
            name=user.name,
            age=user.age,
            gender=user.gender,
            height=user.height,
            weight=user.weight
        )
    )

@app.post("/api/auth/login", response_model=Token)
async def login(credentials: UserLogin):
    user_dict = USERS_DB.get(credentials.email)
    if not user_dict or not pwd_context.verify(credentials.password, user_dict["password_hash"]):
        raise HTTPException(status_code=400, detail="Invalid email or password")
    
    token = create_access_token({"sub": credentials.email})
    return Token(
        access_token=token,
        token_type="bearer",
        user=UserResponse(
            id=user_dict["id"],
            email=user_dict["email"],
            name=user_dict["name"],
            age=user_dict.get("age", 28),
            gender=user_dict.get("gender", "Male"),
            height=user_dict.get("height", 175.0),
            weight=user_dict.get("weight", 70.0)
        )
    )

@app.get("/api/auth/me", response_model=UserResponse)
async def get_me(current_user: UserResponse = Depends(get_current_user)):
    return current_user

# 2. Health Score Engine
@app.post("/api/health-score", response_model=HealthScoreResult)
async def calculate_score(payload: VitalsPayload):
    return calculate_deterministic_health_score(payload)

# 3. Biometrics & Vitals
@app.get("/api/vitals")
async def get_vitals():
    return {
        "vitals": VITALS_DB,
        "blood_pressure": BP_DB
    }

@app.post("/api/vitals")
async def log_vital(vital: VitalLog):
    record = vital.dict()
    record["id"] = f"v_{uuid.uuid4().hex[:8]}"
    record["timestamp"] = datetime.utcnow().isoformat()
    VITALS_DB.insert(0, record)
    return {"message": "Vital logged successfully", "data": record}

@app.post("/api/blood-pressure")
async def log_blood_pressure(bp: BloodPressureLog):
    record = bp.dict()
    record["id"] = f"bp_{uuid.uuid4().hex[:8]}"
    record["timestamp"] = datetime.utcnow().isoformat()
    BP_DB.insert(0, record)
    return {"message": "Blood pressure recorded successfully", "data": record}

# 4. Medical History
@app.get("/api/medical-history")
async def get_medical_history():
    return {"conditions": MEDICAL_HISTORY_DB}

@app.post("/api/medical-history")
async def add_medical_history(condition: Dict[str, str]):
    text = condition.get("condition", "").strip()
    if text and text not in MEDICAL_HISTORY_DB:
        MEDICAL_HISTORY_DB.append(text)
    return {"conditions": MEDICAL_HISTORY_DB}

@app.delete("/api/medical-history/{index}")
async def remove_medical_history(index: int):
    if 0 <= index < len(MEDICAL_HISTORY_DB):
        MEDICAL_HISTORY_DB.pop(index)
    return {"conditions": MEDICAL_HISTORY_DB}

# 5. Clinical AI Symptom Analysis
@app.post("/api/analyze-symptoms", response_model=SymptomAnalysisResponse)
async def analyze_symptoms(request: SymptomAnalysisRequest):
    result = await analyze_symptoms_with_gemini(request.symptoms, request.patient_context)
    return SymptomAnalysisResponse(
        differential_diagnosis=result.get("differential_diagnosis", []),
        severity_level=result.get("severity_level", "Moderate"),
        recommended_actions=result.get("recommended_actions", []),
        disclaimer=result.get("disclaimer", "Clinical AI observation.")
    )

# 6. Clinical Assistant Chat
@app.post("/api/chat")
async def chat_completion(request: ChatRequest):
    messages_payload = [{"role": m.role, "content": m.content} for m in request.messages]
    reply = await generate_chat_response_with_gemini(messages_payload, request.vitals_context)
    return {
        "role": "assistant",
        "content": reply,
        "timestamp": datetime.utcnow().isoformat()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
