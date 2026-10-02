import pytest
from ai.schemas.patient_context import PatientContext
from ai.schemas.lab_report import LabResult
from ai.rag.retriever import MedicalRAGRetriever

@pytest.fixture
def retriever():
    return MedicalRAGRetriever()

def test_kb_loaded_successfully(retriever):
    assert retriever.kb_version == "medical-kb-v1.0"
    assert len(retriever.guidelines) >= 7

def test_retrieve_cardio_guidelines(retriever):
    ctx = PatientContext(symptoms=["crushing chest pain", "shortness of breath"])
    guidelines = retriever.retrieve_guidelines(ctx, top_k=1)
    assert len(guidelines) == 1
    assert guidelines[0]["category"] == "cardiovascular"
    assert "hs_troponin_i" in guidelines[0]["reference_standards"]

def test_retrieve_glycemic_guidelines(retriever):
    ctx = PatientContext(
        lab_results=[LabResult(test_name="Fasting Glucose", value=142, unit="mg/dL", reference_range="70-99", status="potentially_high")]
    )
    guidelines = retriever.retrieve_guidelines(ctx, top_k=1)
    assert len(guidelines) == 1
    assert guidelines[0]["category"] == "endocrine_metabolic"

def test_format_grounded_context_string(retriever):
    ctx = PatientContext(symptoms=["chest pain"])
    retrieved = retriever.retrieve_guidelines(ctx, top_k=1)
    formatted = retriever.format_grounded_context(retrieved)
    assert "RETRIEVED CLINICAL GUIDELINES" in formatted
    assert "medical-kb-v1.0" in formatted
    assert "CARDIOVASCULAR" in formatted
