import pytest
from ai.inference.multimodal_processor import MultimodalDocumentProcessor

def test_multimodal_processor_ocr_normalization():
    proc = MultimodalDocumentProcessor()
    
    # Test normalization
    cleaned, is_assessable = proc.normalize_ocr_text("HGB.....10.2 g/dL")
    assert is_assessable is True
    assert "Hb:" in cleaned
    
    # Test unassessable corruption (abstention trigger)
    corrupted, is_assessable_bad = proc.normalize_ocr_text("H##g? *.* g/d? --- Ref: [?.?]")
    assert is_assessable_bad is False
