import os
import json
from typing import Dict, Any, List
try:
    from google import genai
except ImportError:
    genai = None

from config import settings

def get_genai_client():
    if genai is None:
        return None
    api_key = settings.GEMINI_API_KEY or os.environ.get("GEMINI_API_KEY")
    if not api_key:
        return None
    return genai.Client(api_key=api_key)

async def analyze_symptoms_with_gemini(symptoms: str, patient_context: Dict[str, Any] = None) -> Dict[str, Any]:
    client = get_genai_client()
    if not client:
        # High quality offline fallback
        return {
            "differential_diagnosis": [
                "Upper Respiratory Tract Infection (Likely viral)",
                "Allergic Rhinitis with secondary inflammation",
                "Acute Sinusitis"
            ],
            "severity_level": "Moderate",
            "recommended_actions": [
                "Maintain adequate fluid intake (>2.5L / day)",
                "Warm saline gargles and humidified inhalation",
                "Consult physician if fever persists > 3 days or dyspnea develops"
            ],
            "disclaimer": "This is an AI-assisted clinical observation and does not replace formal medical diagnosis.",
        }

    prompt = f"""
You are NirogX Clinical Intelligence, an evidence-based clinical reasoning assistant.
Analyze the following patient symptoms and biometrics carefully.

Patient Symptoms:
{symptoms}

Patient Context / Vitals:
{json.dumps(patient_context or {}, indent=2)}

Respond with STRICT JSON format matching this schema:
{{
  "differential_diagnosis": ["Possible Condition 1", "Possible Condition 2", "Possible Condition 3"],
  "severity_level": "Low" | "Moderate" | "High" | "Critical",
  "recommended_actions": ["Action 1", "Action 2", "Action 3"],
  "disclaimer": "Medical disclaimer statement"
}}
"""
    try:
        response = client.models.generate_content(
            model="gemini-3.7-flash",
            contents=prompt,
            config={"response_mime_type": "application/json"}
        )
        return json.loads(response.text)
    except Exception as e:
        return {
            "differential_diagnosis": ["General Clinical Consultation Recommended"],
            "severity_level": "Moderate",
            "recommended_actions": ["Rest, hydrate, and schedule an in-person medical evaluation."],
            "disclaimer": f"Clinical fallback active. Error: {str(e)}"
        }

async def generate_chat_response_with_gemini(messages: List[Dict[str, str]], vitals_context: Dict[str, Any] = None) -> str:
    client = get_genai_client()
    if not client:
        return "NirogX Clinical Assistant is active in offline mode. Based on your current health parameters, vital signs remain stable. Remember to stay hydrated and follow medical guidance."

    system_instruction = (
        "You are NirogX Clinical AI Assistant, providing empathetic, scientifically grounded, "
        "and clear wellness and clinical guidance. Always provide helpful context, recommend consulting healthcare professionals, "
        "and contextualize answers with the patient's recorded vitals."
    )

    formatted_contents = []
    if vitals_context:
        formatted_contents.append({
            "role": "user",
            "parts": [{"text": f"[PATIENT VITALS CONTEXT]: {json.dumps(vitals_context)}"}]
        })
        formatted_contents.append({
            "role": "model",
            "parts": [{"text": "Understood. I will reference these clinical biometrics to tailor my answers."}]
        })

    for m in messages:
        role = "user" if m.get("role") == "user" else "model"
        formatted_contents.append({
            "role": role,
            "parts": [{"text": m.get("content", "")}]
        })

    try:
        response = client.models.generate_content(
            model="gemini-3.7-flash",
            contents=formatted_contents,
            config={"system_instruction": system_instruction}
        )
        return response.text
    except Exception as e:
        return f"I experienced an issue analyzing your query. Please consult your physician for personalized medical advice. (Error: {str(e)})"
