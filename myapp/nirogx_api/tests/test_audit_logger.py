import pytest
from ai.safety.audit_logger import PrivacyAuditLogger

def test_privacy_audit_logger_pii_scrubbed():
    logger = PrivacyAuditLogger()
    record = logger.log_inference_event(
        model_version="0.3.0",
        kb_version="medical-kb-v1.0",
        runtime_type="simulated_local_engine",
        latency_breakdown={"total_api_latency_ms": 12.4},
        is_urgent=True,
        confidence_level="HIGH",
        validation_passed=True
    )

    assert record["pii_scrubbed"] is True
    assert record["model_version"] == "0.3.0"
    assert record["kb_version"] == "medical-kb-v1.0"
    assert "event_id" in record
    assert "timestamp" in record
    # Assert zero raw text fields
    assert "symptoms" not in record
    assert "raw_prompt" not in record
    assert "patient_name" not in record
