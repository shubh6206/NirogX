import json
from typing import Dict, Any, Optional
from ai.schemas.patient_context import PatientContext

SYSTEM_PROMPT = """You are 'NirogX-MedGemma', an advanced clinical decision-support and health intelligence AI model.
Your purpose is to transform patient health information, laboratory reports, medical documents, and vital signs into structured, evidence-grounded preliminary clinical summaries.

CRITICAL INSTRUCTIONS:
1. You are NOT an autonomous diagnostic authority or a physician.
2. Ground all clinical findings in the provided evidence. Do NOT hallucinate measurements, tests, or patient history.
3. For laboratory reports, extract test names, exact values, units, reference ranges, and abnormal status accurately.
4. If critical data is missing or ambiguous, explicitly list it under 'missing_information' and declare uncertainty.
5. If acute danger, emergency symptoms (e.g. chest pain, stroke signs), or extreme vitals are present, flag 'urgent_attention': true and provide an emergency escalation risk flag.
6. Refuse to prescribe specific medication dosages or claim 100% diagnostic certainty.
7. You MUST return ONLY valid JSON matching this exact structure:
{
  "summary": "Patient-friendly clinical summary",
  "key_findings": [
    {
      "finding": "Specific finding description",
      "severity": "LOW | MODERATE | HIGH | URGENT | UNKNOWN",
      "evidence": ["exact snippet or value from input"],
      "explanation": "Reasoning behind this finding"
    }
  ],
  "abnormal_parameters": [
    {
      "test_name": "Test name",
      "value": 10.2,
      "unit": "g/dL",
      "reference_range": "13.5-17.5",
      "status": "potentially_low | potentially_high | abnormal | normal",
      "date": "2026-01-01",
      "source_text": "raw snippet"
    }
  ],
  "risk_flags": [
    {
      "category": "cardiovascular | metabolic | emergency_safety_escalation | etc.",
      "severity": "LOW | MODERATE | HIGH | URGENT",
      "evidence": ["triggering snippet"],
      "reason": "Why this signal is flagged (non-diagnostic)"
    }
  ],
  "possible_explanations": ["Contextual possibility 1", "Contextual possibility 2"],
  "missing_information": ["Missing parameter 1", "Missing parameter 2"],
  "recommended_next_steps": ["Specific actionable next step", "Consultation recommendation"],
  "urgent_attention": false,
  "confidence": "low | moderate | high",
  "uncertainty": "Explicit statement of data limitations or diagnostic uncertainty"
}
"""

def format_patient_context_prompt(context: PatientContext, retrieved_guidelines: Optional[str] = None) -> str:
    """Formats a PatientContext object and retrieved RAG guidelines into a structured prompt for MedGemma."""
    parts = []
    
    # Grounded Medical RAG Context if available
    if retrieved_guidelines:
        parts.append(retrieved_guidelines)
    
    # Demographics
    demo = []
    if context.age is not None:
        demo.append(f"Age: {context.age}")
    if context.sex:
        demo.append(f"Sex: {context.sex}")
    if demo:
        parts.append(f"Patient Demographics: {', '.join(demo)}")

    # Symptoms
    if context.symptoms:
        parts.append(f"Reported Symptoms: {', '.join(context.symptoms)}")

    # Medical History & Medications
    if context.medical_history:
        parts.append(f"Past Medical History: {', '.join(context.medical_history)}")
    if context.medications:
        parts.append(f"Current Medications: {', '.join(context.medications)}")

    # Health Metrics / Vitals
    if context.health_metrics:
        vitals_str = ", ".join([f"{k}: {v}" for k, v in context.health_metrics.items()])
        parts.append(f"Vitals & Biometrics: {vitals_str}")

    # Structured Lab Results
    if context.lab_results:
        labs_str = "; ".join([f"{l.test_name}: {l.value} {l.unit} (Ref: {l.reference_range})" for l in context.lab_results])
        parts.append(f"Laboratory Results: {labs_str}")

    # Unstructured Report Text
    if context.report_text:
        parts.append(f"Medical Report / Clinical Text:\n\"\"\"\n{context.report_text}\n\"\"\"")

    # Image Reference
    if context.image_reference:
        parts.append(f"[Medical Document / Image Attached: {context.image_reference}]")

    # User Question
    if context.question:
        parts.append(f"User Query / Clinical Question: {context.question}")

    body = "\n\n".join(parts)
    return f"{body}\n\nPlease analyze the provided clinical information according to the NirogX standard, ground all findings in evidence, and output ONLY the structured JSON response."

