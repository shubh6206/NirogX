import os
import json
import logging
import google.generativeai as genai
from models import SymptomPayload, ClinicalAssessment

logger = logging.getLogger(__name__)

class MedicalAIService:
    def __init__(self):
        # Fetch the API key from environment variables
        api_key = os.environ.get("GEMINI_API_KEY")
        if not api_key:
            logger.warning("GEMINI_API_KEY environment variable not set. AI service will fail.")
            
        # Configure the Gemini client
        genai.configure(api_key=api_key)

        # We use gemini-1.5-flash as it is highly optimized for fast, text-based reasoning
        self.model = genai.GenerativeModel(
            model_name="gemini-1.5-flash",
            system_instruction=(
                "You are 'NirogX', an AI medical assistant. Your role is to provide a preliminary, "
                "evidence-based clinical assessment based on the user's symptoms and duration. "
                "Do not provide a definitive diagnosis. Always advise the user to consult a medical professional. "
                "You must output ONLY valid JSON matching the requested schema."
            )
        )

    def analyze_symptoms(self, payload: SymptomPayload) -> ClinicalAssessment:
        try:
            # Construct the prompt explicitly asking for our exact model keys
            user_prompt = (
                f"The user has the following symptoms: '{payload.text}'.\n"
                f"Duration: '{payload.duration}'.\n\n"
                "Analyze these symptoms and provide a JSON response with exactly these keys:\n"
                "1. 'assessment': A brief, informative summary and preliminary evaluation.\n"
                "2. 'red_flags': A list of strings containing critical warnings (e.g., 'Seek immediate ER care'). Leave empty if none.\n"
                "3. 'confidence_score': A float between 0.0 and 1.0 indicating your confidence."
            )

            # Generate content, explicitly forcing application/json output
            response = self.model.generate_content(
                user_prompt,
                generation_config=genai.GenerationConfig(
                    response_mime_type="application/json",
                    temperature=0.2, # Low temperature keeps the medical advice grounded and deterministic
                )
            )

            # Parse the JSON string returned by Gemini
            response_data = json.loads(response.text)

            # Return the populated Pydantic model directly to main.py
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