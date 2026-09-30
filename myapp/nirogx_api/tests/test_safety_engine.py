import pytest
from ai.schemas.patient_context import PatientContext
from ai.schemas.health_analysis import HealthAnalysisOutput
from ai.safety.rules import SafetyEngine
from ai.safety.sanitizer import OutputSanitizer

@pytest.fixture
def safety_engine():
    return SafetyEngine()

@pytest.fixture
def sanitizer():
    return OutputSanitizer()

def test_emergency_trigger_chest_pain(safety_engine):
    ctx = PatientContext(symptoms=["crushing chest pain radiating to left jaw", "sweating"])
    is_urgent, flags = safety_engine.check_emergency_signals(ctx)
    assert is_urgent is True
    assert len(flags) > 0
    assert flags[0].severity.value == "URGENT"

def test_emergency_trigger_dka_and_stroke(safety_engine):
    dka_ctx = PatientContext(symptoms=["blood sugar 450", "fruity breath", "vomiting"])
    is_urgent, _ = safety_engine.check_emergency_signals(dka_ctx)
    assert is_urgent is True

    stroke_ctx = PatientContext(symptoms=["facial droop", "slurred speech"])
    is_urgent_stroke, _ = safety_engine.check_emergency_signals(stroke_ctx)
    assert is_urgent_stroke is True

def test_extreme_vital_trigger(safety_engine):
    ctx = PatientContext(health_metrics={"heart_rate": 175})
    is_urgent, flags = safety_engine.check_emergency_signals(ctx)
    assert is_urgent is True
    assert any("Extreme physiological heart rate" in f.reason for f in flags)

def test_prescription_boundary_trigger(safety_engine):
    ctx = PatientContext(question="What dose of amoxicillin should I give my child?")
    is_rx, flag = safety_engine.check_prescription_boundaries(ctx)
    assert is_rx is True
    assert flag is not None
    assert flag.category == "clinical_safety_boundary"

def test_biological_implausibility_checker(safety_engine):
    ctx = PatientContext(health_metrics={"SpO2": 145, "body_temp": 62.0})
    is_plausible, errors = safety_engine.validate_biological_plausibility(ctx)
    assert is_plausible is False
    assert len(errors) == 2

def test_output_sanitizer_deduplicates_emergency_actions(sanitizer):
    out = HealthAnalysisOutput(
        summary="I diagnose you with acute coronary syndrome.",
        key_findings=[],
        abnormal_parameters=[],
        risk_flags=[],
        possible_explanations=[],
        missing_information=[],
        recommended_next_steps=[
            "SEEK IMMEDIATE EMERGENCY MEDICAL CARE (Call 911)",
            "Call 911 immediately",
            "Consult your physician for follow-up"
        ],
        urgent_attention=True,
        confidence="high",
        uncertainty=""
    )
    sanitized = sanitizer.sanitize(out, force_urgent=True)
    assert sanitized.urgent_attention is True
    assert sanitized.disclaimer is not None
    assert "preliminary" in sanitized.disclaimer.lower()
    assert "I diagnose you with" not in sanitized.summary
    
    # Must have only 1 emergency recommendation and 1 followup (no duplicates)
    emergency_steps = [s for s in sanitized.recommended_next_steps if "emergency" in s.lower()]
    assert len(emergency_steps) == 1
    assert "112/108/911" in emergency_steps[0]
    assert len(sanitized.recommended_next_steps) == 2
