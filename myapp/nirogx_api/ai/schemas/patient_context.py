from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from .lab_report import LabResult

class PatientContext(BaseModel):
    age: Optional[int] = Field(default=None, description="Patient age in years")
    sex: Optional[str] = Field(default=None, description="Patient sex / gender")
    symptoms: List[str] = Field(default_factory=list, description="Reported patient symptoms")
    medical_history: List[str] = Field(default_factory=list, description="Past medical history and conditions")
    medications: List[str] = Field(default_factory=list, description="Current medications")
    health_metrics: Dict[str, Any] = Field(default_factory=dict, description="Hardware metrics/vitals (heart rate, SpO2, sleep, etc.)")
    lab_results: List[LabResult] = Field(default_factory=list, description="Structured lab results")
    report_text: str = Field(default="", description="Unstructured medical report or clinical notes")
    image_reference: Optional[str] = Field(default=None, description="Path, URL, or base64 token of uploaded medical document/image")
    question: str = Field(default="", description="User or clinician query")
