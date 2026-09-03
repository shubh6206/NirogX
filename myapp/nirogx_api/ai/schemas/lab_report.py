from typing import Optional, Union
from pydantic import BaseModel, Field

class LabResult(BaseModel):
    test_name: str = Field(..., description="Standardized or extracted laboratory test name")
    value: Optional[Union[float, int, str]] = Field(default=None, description="Extracted numerical or categorical value")
    unit: str = Field(default="", description="Measurement unit (e.g. g/dL, mg/dL, bpm)")
    reference_range: str = Field(default="", description="Normal reference range provided in report")
    status: str = Field(default="normal", description="Status e.g. normal, low, high, potentially_low, potentially_high, abnormal")
    date: Optional[str] = Field(default=None, description="Observation or report date (ISO format or extracted string)")
    source_text: str = Field(default="", description="Raw snippet extracted from OCR or report text")
