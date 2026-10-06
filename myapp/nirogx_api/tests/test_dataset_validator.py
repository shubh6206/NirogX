import pytest
import os
import json
from ai.dataset.validator import DatasetValidator, DatasetValidationError

@pytest.fixture
def validator():
    return DatasetValidator(strict_mode=True)

def test_validate_valid_record(validator):
    valid_record = {
        "id": "NX-VAL-001",
        "task": "SYMPTOM_ANALYSIS",
        "input": {
            "symptoms": ["cough"]
        },
        "expected_output": {
            "summary": "Valid clinical summary",
            "key_findings": [],
            "abnormal_parameters": [],
            "risk_flags": [],
            "possible_explanations": [],
            "missing_information": [],
            "recommended_next_steps": [],
            "urgent_attention": False,
            "confidence": "moderate",
            "uncertainty": "Uncertainty note"
        },
        "provenance": {
            "example_id": "NX-VAL-001",
            "dataset_version": "v0.1",
            "source": "synthetic",
            "license": "internal",
            "creation_method": "test",
            "validation_status": "validated"
        }
    }
    is_valid, example, errors = validator.validate_example(valid_record)
    assert is_valid is True
    assert len(errors) == 0

def test_validate_invalid_record_missing_summary(validator):
    invalid_record = {
        "id": "NX-VAL-002",
        "task": "SYMPTOM_ANALYSIS",
        "input": {},
        "expected_output": {
            "summary": "",  # Empty summary
            "key_findings": [],
            "abnormal_parameters": [],
            "risk_flags": [],
            "possible_explanations": [],
            "missing_information": [],
            "recommended_next_steps": [],
            "urgent_attention": False,
            "confidence": "low",
            "uncertainty": ""
        },
        "provenance": {
            "example_id": "NX-VAL-002",
            "dataset_version": "v0.1",
            "source": "synthetic",
            "license": "internal",
            "creation_method": "test",
            "validation_status": "validated"
        }
    }
    is_valid, example, errors = validator.validate_example(invalid_record)
    assert is_valid is False
    assert any("summary" in e.lower() for e in errors)

def test_verify_no_contamination_detects_leak(tmp_path):
    validator = DatasetValidator(strict_mode=True)
    gold_file = tmp_path / "gold.json"
    cand_file = tmp_path / "train.json"

    gold_data = [{"id": "NX-GOLD-001", "input": {"symptoms": ["chest pain"]}}]
    cand_data = [{"id": "NX-GOLD-001", "input": {"symptoms": ["cough"]}}]  # Leaked ID

    with open(gold_file, "w") as f:
        json.dump(gold_data, f)
    with open(cand_file, "w") as f:
        json.dump(cand_data, f)

    with pytest.raises(DatasetValidationError) as exc:
        validator.verify_no_contamination(str(gold_file), str(cand_file))
    assert "Contamination Detected" in str(exc.value)
