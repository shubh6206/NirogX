import pytest
from pydantic import ValidationError
from ai.schemas import (
    TaskType,
    Finding,
    SeverityEnum,
    RiskFlag,
    LabResult,
    PatientContext,
    HealthAnalysisOutput,
    HealthAnalysisRequest,
    NirogXDatasetExample,
    ProvenanceMetadata
)

def test_finding_schema_valid():
    f = Finding(
        finding="Microcytic hypochromic anemia pattern",
        severity=SeverityEnum.MODERATE,
        evidence=["Hb: 10.2 g/dL", "MCV: 76 fL"],
        explanation="Low hemoglobin and MCV."
    )
    assert f.severity == SeverityEnum.MODERATE
    assert len(f.evidence) == 2

def test_finding_schema_invalid_severity():
    with pytest.raises(ValidationError):
        Finding(finding="Test", severity="EXTREME_CRITICAL")

def test_lab_result_numerical_and_qualitative():
    num_lab = LabResult(test_name="Potassium", value=4.2, unit="mEq/L", reference_range="3.5-5.0", status="normal")
    assert num_lab.value == 4.2

    str_lab = LabResult(test_name="Urine Protein", value="2+", unit="qualitative", reference_range="Negative", status="abnormal")
    assert str_lab.value == "2+"

def test_health_analysis_output_schema():
    out = HealthAnalysisOutput(
        summary="Preliminary assessment summary",
        key_findings=[],
        abnormal_parameters=[],
        risk_flags=[],
        possible_explanations=["General variation"],
        missing_information=["History"],
        recommended_next_steps=["Followup"],
        urgent_attention=False,
        confidence="moderate",
        uncertainty="Data limitations"
    )
    assert out.urgent_attention is False
    assert out.disclaimer is not None
    assert "preliminary" in out.disclaimer.lower()

def test_dataset_example_validation():
    ex = NirogXDatasetExample(
        id="NX-TEST-001",
        task=TaskType.SYMPTOM_ANALYSIS,
        input=PatientContext(symptoms=["mild headache"]),
        expected_output=HealthAnalysisOutput(
            summary="Symptom evaluation",
            key_findings=[],
            abnormal_parameters=[],
            risk_flags=[],
            possible_explanations=[],
            missing_information=[],
            recommended_next_steps=[],
            urgent_attention=False,
            confidence="low",
            uncertainty="Preliminary assessment"
        ),
        provenance=ProvenanceMetadata(
            example_id="NX-TEST-001",
            dataset_version="v0.1",
            source="synthetic",
            license="internal",
            creation_method="test",
            validation_status="validated"
        )
    )
    assert ex.id == "NX-TEST-001"
