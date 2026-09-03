from typing import List
from pydantic import BaseModel, Field
from .finding import SeverityEnum

class RiskFlag(BaseModel):
    category: str = Field(..., description="Category of risk signal (e.g. cardiovascular, metabolic, acute_symptom)")
    severity: SeverityEnum = Field(default=SeverityEnum.MODERATE, description="Risk signal severity level")
    evidence: List[str] = Field(default_factory=list, description="Observations triggering this signal")
    reason: str = Field(..., description="Explanation of the risk signal (non-diagnostic decision support)")
