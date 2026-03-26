import os
import json
import logging
import pandas as pd
import google.generativeai as genai
from sqlalchemy.orm import Session
from models import SymptomPayload, ClinicalAssessment

# Import the matrix generator we built earlier
from ml_pipeline import generate_user_feature_matrix 

logger = logging.getLogger(__name__)

class MedicalAIService:
    def __init__(self):
        api_key = os.environ.get("GEMINI_API_KEY")
        if not api_key:
            logger.warning("GEMINI_API_KEY environment variable not set. AI service will fail.")
            
        genai.configure(api_key=api_key)

        self.model = genai.GenerativeModel(
            model_name="gemini-2.5-flash",
            system_instruction=(
                "You are 'NirogX', an AI medical assistant. Your role is to provide a preliminary, "
                "evidence-based clinical assessment based on the user's symptoms and their recent biometric data. "
                "Do not provide a definitive diagnosis. Always advise the user to consult a medical professional. "
                "You must output ONLY valid JSON matching the requested schema."
            )
        )

    # Added db: Session to the parameters
    def analyze_symptoms(self, payload: SymptomPayload, db: Session = None) -> ClinicalAssessment:
        try:
            biometric_context = "No recent biometric data available."

            # 1. Fetch and format the hardware vitals if a user_id and DB are provided
            if payload.user_id and db:
                try:
                    # Fetch daily averages
                    user_matrix = generate_user_feature_matrix(db, int(payload.user_id), freq='1D')
                    
                    if not user_matrix.empty:
                        # Grab the most recent row (e.g., today's data)
                        latest_vitals = user_matrix.iloc[-1]
                        
                        # Format it into a clean string for the LLM
                        biometrics = []
                        # Map standard vitals
                        vital_map = {
                            'heart_rate': ('Resting Heart Rate', 'bpm'),
                            'body_temp': ('Body Temp', '°C'),
                            'SpO2': ('SpO2', '%'),
                            'systolic': ('Systolic BP', 'mmHg'),
                            'diastolic': ('Diastolic BP', 'mmHg')
                        }
                        
                        for key, (label, unit) in vital_map.items():
                            if key in latest_vitals and not pd.isna(latest_vitals[key]):
                                biometrics.append(f"{label}: {latest_vitals[key]:.1f} {unit}")
                        
                        if biometrics:
                            biometric_context = ", ".join(biometrics)
                except Exception as db_e:
                    logger.warning(f"Could not fetch biometric context for user {payload.user_id}: {db_e}")

            # 2. Construct the enriched prompt
            user_prompt = (
                f"The user has reported the following symptoms: '{payload.text}'.\n"
                f"Symptom Duration: '{payload.duration}'.\n"
                f"Recent Hardware Biometrics (Last 24h): {biometric_context}\n\n"
                "Analyze these symptoms alongside the biometric data and provide a JSON response with exactly these keys:\n"
                "1. 'assessment': A brief, informative summary and preliminary evaluation.\n"
                "2. 'red_flags': A list of strings containing critical warnings. Leave empty if none.\n"
                "3. 'confidence_score': A float between 0.0 and 1.0 indicating your confidence."
            )

            # 3. Generate Content
            response = self.model.generate_content(
                user_prompt,
                generation_config=genai.GenerationConfig(
                    response_mime_type="application/json",
                    temperature=0.2, 
                )
            )

            response_data = json.loads(response.text)

            return ClinicalAssessment(
                assessment=response_data.get("assessment", "Could not generate assessment."),
                red_flags=response_data.get("red_flags", []),
                confidence_score=float(response_data.get("confidence_score", 0.0))
            )

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse Gemini JSON response: {e}\nRaw Output: {response.text}")
            return ClinicalAssessment(
                assessment="Error: AI provided an invalid response format. Please consult a doctor.",
                red_flags=["System Error"],
                confidence_score=0.0
            )
        except Exception as e:
            logger.error(f"Error communicating with Gemini API: {e}")
            return ClinicalAssessment(
                assessment="An error occurred while analyzing the symptoms. Please consult a healthcare provider directly.",
                red_flags=[],
                confidence_score=0.0
            )
