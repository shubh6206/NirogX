from enum import Enum
from pydantic import BaseModel, Field
from typing import List, Optional

# -------------------------------------------------------------------
# Enums for strict validation
# -------------------------------------------------------------------
class ActivityLevelEnum(str, Enum):
    sedentary = "sedentary"
    light = "light"
    moderate = "moderate"
    active = "active"
    very_active = "very_active"

# -------------------------------------------------------------------
# Request Payloads
# -------------------------------------------------------------------
class SymptomPayload(BaseModel):
    # Using text for NLP-based AI processing
    text: str = Field(
        ..., 
        min_length=3,
        description="Natural language description of the symptoms.",
        json_schema_extra={"example": "I have been experiencing a sharp chest pain and shortness of breath."}
    )
    duration: str = Field(
        ..., 
        description="How long the symptoms have been present.",
        json_schema_extra={"example": "2 days"}
    )
    # Adding an optional user_id is good practice for saving to a database later
    user_id: Optional[str] = Field(
        None, 
        description="Optional unique identifier for the user."
    )

class UserVitalsPayload(BaseModel):
    age: int = Field(..., gt=0, lt=120, description="User's age in years.")
    bmi: float = Field(..., gt=10.0, lt=60.0, description="Body Mass Index.")
    heart_rate: int = Field(..., gt=30, lt=220, description="Resting heart rate in BPM.")
    sleep_hours: float = Field(..., ge=0.0, le=24.0, description="Average hours of sleep per night.")
    activity_level: ActivityLevelEnum = Field(
        ..., 
        description="Standardized activity level."
    )

# -------------------------------------------------------------------
# Response Models
# -------------------------------------------------------------------
class ClinicalAssessment(BaseModel):
    assessment: str = Field(
        ..., 
        description="The AI-generated clinical assessment text."
    )
    # Added red_flags so the Flutter app can highlight urgent issues in the UI
    red_flags: List[str] = Field(
        default_factory=list,
        description="List of critical warnings requiring immediate attention."
    )
    confidence_score: float = Field(
        default=0.0, 
        ge=0.0, le=1.0, 
        description="AI confidence level from 0.0 to 1.0."
    )

class HealthScore(BaseModel):
    score: float = Field(
        ..., 
        ge=0.0, le=100.0, 
        description="Calculated health score out of 100."
    )
    # Added a status category to make it easier to display colored rings (Green/Yellow/Red) in Flutter
    status: str = Field(
        default="unknown",
        description="Categorized status (e.g., 'Optimal', 'Caution', 'Critical')."
    )

# -------------------------------------------------------------------
# Database / History Models
# -------------------------------------------------------------------
class AnalysisHistory(BaseModel):
    record_id: str = Field(..., description="Unique ID for this specific analysis record.")
    timestamp: str = Field(..., description="ISO 8601 timestamp of when the analysis occurred.")
    symptom_payload: SymptomPayload
    clinical_assessment: ClinicalAssessment