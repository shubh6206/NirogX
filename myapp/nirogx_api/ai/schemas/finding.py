from enum import Enum
from typing import List
from pydantic import BaseModel, Field

class SeverityEnum(str, Enum):
    LOW = "LOW"
    MODERATE = "MODERATE"
    HIGH = "HIGH"
    URGENT = "URGENT"
    UNKNOWN = "UNKNOWN"

class Finding(BaseModel):
    finding: str = Field(..., description="Description of the clinical or observation finding")
    severity: SeverityEnum = Field(default=SeverityEnum.LOW, description="Severity assessment")
    evidence: List[str] = Field(default_factory=list, description="Grounding evidence strings or source references")
    explanation: str = Field(default="", description="Contextual reasoning explaining the finding")
