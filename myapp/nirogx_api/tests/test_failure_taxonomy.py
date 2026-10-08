import pytest
from ai.evaluation.failure_taxonomy import FailureTaxonomyQuantifier, FailureCategoryEnum

def test_failure_taxonomy_recording():
    quantifier = FailureTaxonomyQuantifier()
    quantifier.record_failure(
        case_id="GOLD-001",
        task="EMERGENCY_TRIAGE",
        category=FailureCategoryEnum.URGENT_FALSE_NEGATIVE,
        details="Missed atypical angina",
        expected=True,
        actual=False
    )
    quantifier.record_failure(
        case_id="GOLD-002",
        task="LAB_EXTRACTION",
        category=FailureCategoryEnum.LAB_VALUE_EXTRACTION_ERROR,
        details="Missed eGFR value",
        expected=[("eGFR", "potentially_low")],
        actual=[]
    )

    summary = quantifier.get_summary()
    assert summary["total_failure_instances"] == 2
    assert summary["failure_taxonomy_breakdown"]["URGENT_FALSE_NEGATIVE"]["count"] == 1
    assert summary["failure_taxonomy_breakdown"]["LAB_VALUE_EXTRACTION_ERROR"]["count"] == 1
    assert summary["failure_taxonomy_breakdown"]["UNSUPPORTED_CLAIM"]["count"] == 0
