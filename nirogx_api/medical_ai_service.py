import os
from openai import OpenAI
from models import SymptomPayload

class MedicalAIService:
    def __init__(self):
        # In a real application, consider a more robust way to manage the API key and base URL.
        self.client = OpenAI(
            base_url=os.environ.get("OLLAMA_BASE_URL", "http://localhost:11434/v1"),
            api_key=os.environ.get("OLLAMA_API_KEY", "ollama"),
        )
        self.model_name = "biomistral"
        self.system_prompt = (
            "You are an AI medical assistant. Your role is to provide a preliminary, evidence-based clinical assessment. "
            "Do not provide a diagnosis. Your response should be a brief, informative summary based on the user's symptoms, "
            "and you should advise the user to consult a medical professional for a definitive diagnosis."
        )

    def analyze_symptoms(self, payload: SymptomPayload) -> str:
        try:
            user_prompt = f"The user has the following symptoms: {payload.text}. The symptoms have been present for {payload.duration}."
            
            response = self.client.chat.completions.create(
                model=self.model_name,
                messages=[
                    {"role": "system", "content": self.system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                temperature=0.3, # Lower temperature for more deterministic, fact-based responses
            )
            
            if response.choices:
                return response.choices[0].message.content.strip()
            else:
                return "Could not generate an assessment. Please try again."
                
        except Exception as e:
            # In a production environment, log the error for debugging.
            print(f"Error communicating with LLM: {e}")
            return "An error occurred while analyzing the symptoms. Please consult a healthcare provider directly."

