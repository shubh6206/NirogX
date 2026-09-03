import pytest
import os
from ai.schemas.patient_context import PatientContext
from ai.schemas.provenance import RuntimeProvenance
from ai.inference.medgemma import MedGemmaInferenceEngine, RealModelExecutionError, RemoteModelConnectionError
from services.medgemma_service import MedGemmaService
from ai.schemas.health_analysis import HealthAnalysisRequest

def test_runtime_provenance_enum_values():
    """Verify supported provenance values and boolean check."""
    assert RuntimeProvenance.REAL_MEDGEMMA_COLAB.value == "real_medgemma_colab"
    assert RuntimeProvenance.REAL_MEDGEMMA_LOCAL_GPU.value == "real_medgemma_local_gpu"
    assert RuntimeProvenance.REAL_MEDGEMMA_ADAPTER_GPU.value == "real_medgemma_adapter_gpu"
    assert RuntimeProvenance.SIMULATED_LOCAL_ENGINE.value == "simulated_local_engine"

    assert RuntimeProvenance.REAL_MEDGEMMA_COLAB.is_real_model() is True
    assert RuntimeProvenance.REAL_MEDGEMMA_LOCAL_GPU.is_real_model() is True
    assert RuntimeProvenance.REAL_MEDGEMMA_ADAPTER_GPU.is_real_model() is True
    assert RuntimeProvenance.SIMULATED_LOCAL_ENGINE.is_real_model() is False

def test_evaluation_mode_forbids_simulation_locally():
    """Verify that when evaluation_mode=True, missing local GPU/model raises RealModelExecutionError instead of simulating."""
    with pytest.raises(RealModelExecutionError) as exc_info:
        engine = MedGemmaInferenceEngine(
            model_name_or_path="google/medgemma-1.5-4b-it-nonexistent-path-test",
            remote_api_url=None,
            evaluation_mode=True
        )
    assert "MEDGEMMA_EVALUATION_MODE is enabled" in str(exc_info.value)

def test_evaluation_mode_forbids_failed_remote_fallback():
    """Verify that when evaluation_mode=True, an unreachable remote URL raises RemoteModelConnectionError without fallback."""
    engine = MedGemmaInferenceEngine(
        remote_api_url="http://127.0.0.1:59999",  # Non-existent local port
        evaluation_mode=True
    )
    context = PatientContext(
        symptoms=["cough", "chest pain"],
        question="What is the assessment?"
    )
    with pytest.raises(RemoteModelConnectionError) as exc_info:
        engine.generate_analysis(context)
    assert "MEDGEMMA_EVALUATION_MODE is enabled" in str(exc_info.value)

def test_provenance_tag_on_simulated_mode():
    """Verify that development simulated mode explicitly returns 'simulated_local_engine' provenance."""
    engine = MedGemmaInferenceEngine(
        model_name_or_path="nonexistent",
        remote_api_url=None,
        use_fallback_if_unavailable=True,
        evaluation_mode=False
    )
    context = PatientContext(
        symptoms=["headache"],
        question="Recommendation?"
    )
    output, latency = engine.generate_analysis(context)
    assert output is not None
    assert output.get("_runtime_provenance") == RuntimeProvenance.SIMULATED_LOCAL_ENGINE.value
    assert engine.runtime_type == RuntimeProvenance.SIMULATED_LOCAL_ENGINE.value

def test_service_attaches_runtime_provenance_to_telemetry():
    """Verify MedGemmaService includes runtime_type in metadata telemetry."""
    service = MedGemmaService(remote_api_url=None, evaluation_mode=False)
    req = HealthAnalysisRequest(
        symptoms=["mild rash"],
        question="Advice?"
    )
    analysis, telemetry = service.analyze_health(req)
    assert analysis is not None
    assert "runtime_type" in telemetry
    assert telemetry["runtime_type"] == RuntimeProvenance.SIMULATED_LOCAL_ENGINE.value
