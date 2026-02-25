from pydantic import BaseModel
from typing import Optional

class SymptomPayload(BaseModel):
    text: str
    duration: str

class UserVitalsPayload(BaseModel):
    age: int
    bmi: float
    heart_rate: int
    sleep_hours: float
    activity_level: str

class ClinicalAssessment(BaseModel):
    assessment: str

class HealthScore(BaseModel):
    score: float

class AnalysisHistory(BaseModel):
    symptom_payload: SymptomPayload
    clinical_assessment: ClinicalAssessment
