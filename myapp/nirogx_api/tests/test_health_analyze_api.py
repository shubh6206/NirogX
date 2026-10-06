import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_health_analyze_api_valid_symptoms():
    payload = {
        "symptoms": ["fatigue", "dizziness"],
        "health_metrics": {
            "heart_rate": 88,
            "sleep_hours": 6.5
        },
        "question": "What could be causing my fatigue?"
    }
    response = client.post("/api/v1/health/analyze", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["model"] == "nirogx-medgemma-4b"
    assert "analysis" in data
    assert "summary" in data["analysis"]
    assert "disclaimer" in data["analysis"]
    assert data["metadata"]["latency_ms"] >= 0

def test_health_analyze_api_emergency_escalation():
    payload = {
        "symptoms": ["crushing chest pain radiating to arm", "shortness of breath"]
    }
    response = client.post("/api/v1/health/analyze", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["analysis"]["urgent_attention"] is True
    assert len(data["analysis"]["risk_flags"]) > 0
    assert any("emergency" in f["category"] for f in data["analysis"]["risk_flags"])

def test_health_analyze_api_lab_extraction_payload():
    payload = {
        "medical_report": "CBC Panel: Hemoglobin 9.4 g/dL (Ref: 12.0-16.0), Platelets 210 x10^3/uL."
    }
    response = client.post("/api/v1/health/analyze", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "analysis" in data
    assert data["analysis"]["summary"] is not None

def test_existing_endpoints_unaffected():
    # Verify existing /api/medical-history
    res = client.get("/api/medical-history")
    assert res.status_code == 200
    assert "conditions" in res.json()
