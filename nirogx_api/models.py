from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional, Dict, Any
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr
    name: str
    age: int = 28
    gender: str = "Male"
    height: float = 175.0
    weight: float = 70.0

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(UserBase):
    id: str
    created_at: datetime = Field(default_factory=datetime.utcnow)

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

class VitalLog(BaseModel):
    type: str  # heart_rate, SpO2, blood_pressure, sleep, steps, active_calories
    value: float
    value_secondary: Optional[float] = None
    unit: str
    source: str = "Manual Entry"
    timestamp: datetime = Field(default_factory=datetime.utcnow)

class BloodPressureLog(BaseModel):
    systolic: int
    diastolic: int
    pulse: Optional[int] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)

class VitalsPayload(BaseModel):
    age: int = 28
    bmi: float = 22.9
    heart_rate: int = 68
    sleep_hours: float = 7.6
    activity_level: str = "moderate"  # sedentary, light, moderate, active, very_active
    hydration_liters: Optional[float] = 1.75
    systolic_bp: Optional[int] = 118
    diastolic_bp: Optional[int] = 78

class HealthScoreComponent(BaseModel):
    score: float
    rawWeight: float
    normalizedWeight: float
    isAvailable: bool = True
    label: str
    currentDisplay: str
    benchmarkDisplay: str
    status: str

class HealthScoreResult(BaseModel):
    score: float
    status: str
    evaluatedCategories: int
    totalCategories: int
    components: Dict[str, HealthScoreComponent]
    helpingFactors: List[str]
    improvementOpportunities: List[str]
    explanation: str
    changeDelta: Optional[float] = 0.0
    calculatedAt: datetime = Field(default_factory=datetime.utcnow)

class SymptomAnalysisRequest(BaseModel):
    symptoms: str
    patient_context: Optional[Dict[str, Any]] = None
    report_image_base64: Optional[str] = None

class SymptomAnalysisResponse(BaseModel):
    differential_diagnosis: List[str]
    severity_level: str  # Low, Moderate, High, Critical
    recommended_actions: List[str]
    disclaimer: str
    analyzed_at: datetime = Field(default_factory=datetime.utcnow)

class ChatMessage(BaseModel):
    role: str  # user, assistant, system
    content: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)

class ChatRequest(BaseModel):
    messages: List[ChatMessage]
    vitals_context: Optional[Dict[str, Any]] = None
