from fastapi import FastAPI, HTTPException
from models import (
    SymptomPayload,
    UserVitalsPayload,
    ClinicalAssessment,
    HealthScore,
)
from medical_ai_service import MedicalAIService
from health_score_calculator import HealthScoreCalculator

app = FastAPI(
    title="NirogX API",
    description="API for symptom analysis and health score calculation.",
    version="1.0.0",
)

# Initialize services
medical_ai_service = MedicalAIService()
health_score_calculator = HealthScoreCalculator()

@app.post("/api/v1/analyze", response_model=ClinicalAssessment)
def analyze_symptoms_endpoint(payload: SymptomPayload):
    """
    Accepts user symptoms and returns a preliminary clinical assessment.
    """
    assessment_text = medical_ai_service.analyze_symptoms(payload)
    if "error" in assessment_text.lower():
        raise HTTPException(status_code=500, detail=assessment_text)
    return ClinicalAssessment(assessment=assessment_text)

@app.post("/api/v1/health-score", response_model=HealthScore)
def calculate_health_score_endpoint(payload: UserVitalsPayload):
    """
    Calculates a health score based on user vitals and lifestyle.
    """
    score = health_score_calculator.calculate_score(payload)
    return HealthScore(score=score)

@app.get("/")
def read_root():
    return {"message": "Welcome to the NirogX API"}
