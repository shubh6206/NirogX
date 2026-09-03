import pytest
import os
from ai.schemas.patient_context import PatientContext
from ai.inference.medgemma import MedGemmaInferenceEngine
from services.medgemma_service import MedGemmaService
from ai.schemas.health_analysis import HealthAnalysisRequest

def test_medgemma_engine_remote_fallback():
    """Verify that MedGemma engine gracefully falls back to simulated engine if remote URL fails."""
    engine = MedGemmaInferenceEngine(
        remote_api_url="http://invalid-colab-tunnel-address.test",
        use_fallback_if_unavailable=True
    )
    context = PatientContext(
        symptoms=["mild headache"],
        question="How to manage tension headache?"
    )
    output, latency = engine.generate_analysis(context)
    assert output is not None
    assert "summary" in output
    assert latency >= 0.0

def test_medgemma_service_with_remote_config():
    """Verify MedGemmaService initializes and produces analysis with remote endpoint configured."""
    service = MedGemmaService(remote_api_url="http://invalid-colab-tunnel-address.test")
    req = HealthAnalysisRequest(
        symptoms=["fever", "cough"],
        question="What are next steps?"
    )
    analysis, telemetry = service.analyze_health(req)
    assert analysis is not None
    assert analysis.summary is not None
    assert analysis.disclaimer is not None
    assert "gate1_safety_ms" in telemetry["latency_breakdown_ms"]

