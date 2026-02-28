import logging
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware

# Import Pydantic models (The API Contract)
from models import (
    SymptomPayload,
    UserVitalsPayload,
    ClinicalAssessment,
    HealthScore,
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
    ai_service: MedicalAIService = Depends(get_medical_ai_service)
):
    """
    Accepts user symptoms and returns a preliminary clinical assessment.
    """
    logger.info(f"Received symptom analysis request for user: {getattr(payload, 'user_id', 'unknown')}")
    
    try:
        # Assuming your service returns a structured ClinicalAssessment or a string
        result = ai_service.analyze_symptoms(payload)
        
        # If your service returns a raw string, construct the model:
        if isinstance(result, str):
            if "error" in result.lower():
                raise ValueError(result)
            return ClinicalAssessment(assessment=result, red_flags=[], confidence_score=0.0)
            
        # If your service already returns a ClinicalAssessment Pydantic model:
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
        score = score_calculator.calculate_score(payload)
        return HealthScore(score=score)
        
    except ValueError as ve:
        logger.warning(f"Invalid vitals payload: {str(ve)}")
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        logger.error(f"Unexpected error calculating health score: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error during scoring.")