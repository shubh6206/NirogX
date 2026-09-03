from enum import Enum
from typing import List, Optional, Dict, Any, Union
from pydantic import BaseModel, Field
from .tasks import TaskType
from .finding import Finding
from .risk_flag import RiskFlag
from .lab_report import LabResult
from .patient_context import PatientContext

class ConfidenceLevelEnum(str, Enum):
    HIGH = "HIGH"
    MODERATE = "MODERATE"
    LOW = "LOW"
    NOT_ASSESSABLE = "NOT_ASSESSABLE"

class HealthAnalysisOutput(BaseModel):
    summary: str = Field(..., description="Concise, patient-friendly clinical summary")
    key_findings: List[Finding] = Field(default_factory=list, description="Structured key clinical findings with severity and evidence")
    abnormal_parameters: List[LabResult] = Field(default_factory=list, description="List of parameters falling outside normal thresholds")
    risk_flags: List[RiskFlag] = Field(default_factory=list, description="Identified risk signals or safety flags")
    possible_explanations: List[str] = Field(default_factory=list, description="Contextual possibilities without definitive diagnostic claims")
    missing_information: List[str] = Field(default_factory=list, description="Missing clinical parameters, history, or context needed")
    recommended_next_steps: List[str] = Field(default_factory=list, description="Evidence-backed next actions, checkups, or physician consultations")
    urgent_attention: bool = Field(default=False, description="Flag indicating requirement for immediate emergency/urgent medical evaluation")
    confidence: Union[ConfidenceLevelEnum, str] = Field(default=ConfidenceLevelEnum.LOW, description="Calibrated confidence level: HIGH, MODERATE, LOW, NOT_ASSESSABLE")
    uncertainty: str = Field(default="", description="Explicit communication of clinical uncertainty or data limitations")
    disclaimer: Optional[str] = Field(
        default="AI-generated health information is preliminary and does not replace evaluation by a qualified healthcare professional.",
        description="Deterministic safety disclaimer injected by system"
    )

class HealthAnalysisRequest(BaseModel):
    patient_context: Optional[PatientContext] = None
    symptoms: List[str] = Field(default_factory=list)
    health_metrics: Dict[str, Any] = Field(default_factory=dict)
    lab_results: List[LabResult] = Field(default_factory=list)
    medical_report: Optional[str] = None
    image: Optional[str] = None
    question: Optional[str] = ""

class EvaluationMetadata(BaseModel):
    difficulty: str = Field(default="medium")
    domain: str = Field(default="general_medicine")
    expected_urgency: bool = Field(default=False)
    target_abnormalities: List[str] = Field(default_factory=list)
    critical_risk_flags: List[str] = Field(default_factory=list)

class ProvenanceMetadata(BaseModel):
    example_id: str
    dataset_version: str = "nirogx-medical-dataset-v0.1"
    source: str = "synthetic"  # synthetic, clinical_gold, curated_benchmark
    license: str = "internal-research-only"
    creation_method: str = "expert_curated"  # expert_curated, template_generator
    validation_status: str = "validated"  # pending, validated, rejected

class NirogXDatasetExample(BaseModel):
    id: str = Field(..., description="Unique example ID e.g. NX-GOLD-001 or NX-PILOT-0001")
    task: TaskType = Field(..., description="Specific AI task type")
    input: PatientContext = Field(..., description="Input context including demographics, vitals, labs, symptoms")
    expected_output: HealthAnalysisOutput = Field(..., description="Gold standard or expected target output")
    evaluation_metadata: Optional[EvaluationMetadata] = None
    provenance: ProvenanceMetadata
