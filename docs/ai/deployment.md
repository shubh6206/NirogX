# NirogX AI Model Deployment & API Reference

## 1. FastAPI Endpoint Reference

### `POST /api/v1/health/analyze`
Clinical intelligence and health analysis endpoint.

#### Request Body:
```json
{
  "patient_context": {
    "age": 34,
    "sex": "Female",
    "symptoms": ["fatigue", "dizziness"],
    "health_metrics": {
      "heart_rate": 84,
      "sleep_hours": 6.8
    },
    "lab_results": [
      {
        "test_name": "Hemoglobin",
        "value": 10.4,
        "unit": "g/dL",
        "reference_range": "12.0-15.5",
        "status": "potentially_low"
      }
    ]
  },
  "question": "What might be contributing to my low energy?"
}
```

#### Response Body:
```json
{
  "model": "nirogx-medgemma-4b",
  "version": "0.1.0",
  "analysis": {
    "summary": "Clinical preliminary summary for 34-year-old female...",
    "key_findings": [
      {
        "finding": "Observed mild reduction in hemoglobin",
        "severity": "MODERATE",
        "evidence": ["Hemoglobin: 10.4 g/dL"],
        "explanation": "Value falls below female reference threshold."
      }
    ],
    "abnormal_parameters": [
      {
        "test_name": "Hemoglobin",
        "value": 10.4,
        "unit": "g/dL",
        "reference_range": "12.0-15.5",
        "status": "potentially_low"
      }
    ],
    "risk_flags": [],
    "possible_explanations": ["Mild nutritional deficiency or physiological variation"],
    "missing_information": ["Ferritin / iron studies", "Dietary history"],
    "recommended_next_steps": ["Consult treating physician for clinical correlation"],
    "urgent_attention": false,
    "confidence": "high",
    "uncertainty": "Preliminary assessment; requires clinical review.",
    "disclaimer": "AI-generated health information is preliminary and does not replace evaluation by a qualified healthcare professional."
  },
  "metadata": {
    "latency_ms": 12,
    "inference_latency_ms": 10
  }
}
```

## 2. Local Hardware & Inference Setup
* **Recommended GPU**: NVIDIA RTX 3080/4080 (8GB–16GB VRAM) for 4-bit NF4 quantized inference.
* **CPU / Test Mode**: Automatic fallback to simulated baseline inference when discrete GPU or PyTorch is offline, ensuring zero server downtime.
