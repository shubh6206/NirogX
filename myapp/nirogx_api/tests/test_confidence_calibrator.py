import pytest
from ai.schemas.patient_context import PatientContext
from ai.schemas.lab_report import LabResult
from ai.schemas.health_analysis import ConfidenceLevelEnum
from ai.safety.confidence_calibrator import ConfidenceCalibrator

@pytest.fixture
def calibrator():
    return ConfidenceCalibrator()

def test_calibrate_high_confidence_multi_source(calibrator):
    ctx = PatientContext(
        health_metrics={"heart_rate": 72, "sleep_hours": 7.5},
        lab_results=[LabResult(test_name="Hemoglobin", value=14.2, unit="g/dL", reference_range="13.5-17.5", status="normal")],
        symptoms=["None"]
    )
    conf, reason = calibrator.calibrate(ctx)
    assert conf == ConfidenceLevelEnum.HIGH
    assert "High confidence" in reason

def test_calibrate_moderate_confidence_symptom_cluster(calibrator):
    ctx = PatientContext(
        symptoms=["fatigue for 2 weeks", "intermittent dizziness", "morning stiffness"]
    )
    conf, reason = calibrator.calibrate(ctx)
    assert conf == ConfidenceLevelEnum.MODERATE
    assert "Moderate confidence" in reason

def test_calibrate_low_confidence_sparse_input(calibrator):
    ctx = PatientContext(
        symptoms=["mild headache"]
    )
    conf, reason = calibrator.calibrate(ctx)
    assert conf == ConfidenceLevelEnum.LOW
    assert "Low confidence" in reason

def test_calibrate_not_assessable_implausible(calibrator):
    ctx = PatientContext(
        health_metrics={"SpO2": 150}
    )
    conf, reason = calibrator.calibrate(ctx, is_biologically_implausible=True)
    assert conf == ConfidenceLevelEnum.NOT_ASSESSABLE
    assert "NOT_ASSESSABLE" in reason
