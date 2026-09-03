import logging
from typing import Dict, Any, Tuple, Optional
from pydantic import ValidationError

from ai.schemas.health_analysis import HealthAnalysisOutput
from ai.schemas.finding import Finding, SeverityEnum
from ai.schemas.risk_flag import RiskFlag

logger = logging.getLogger(__name__)

class SafetyOutputValidator:
    def validate_and_fallback(self, raw_output: Dict[str, Any]) -> HealthAnalysisOutput:
        """
        Validates LLM output against Pydantic schema.
        If malformed or invalid JSON, constructs a safe fallback object without crashing.
        """
        try:
            return HealthAnalysisOutput.model_validate(raw_output)
        except (ValidationError, Exception) as e:
            logger.error(f"Model output schema validation failed: {e}. Generating safe fallback.")
            return HealthAnalysisOutput(
                summary="Unable to parse detailed structured analysis. Please consult a healthcare professional.",
                key_findings=[
                    Finding(
                        finding="Inference parsing fallback triggered",
                        severity=SeverityEnum.UNKNOWN,
                        evidence=[],
                        explanation="The system could not validate model output structure."
                    )
                ],
                abnormal_parameters=[],
                risk_flags=[
                    RiskFlag(
                        category="system_validation_notice",
                        severity=SeverityEnum.LOW,
                        evidence=[],
                        reason="Standard schema validation failed; fallback output generated."
                    )
                ],
                possible_explanations=[],
                missing_information=["Full clinical dataset re-submission"],
                recommended_next_steps=["Consult your healthcare provider directly."],
                urgent_attention=False,
                confidence="low",
                uncertainty="Automated parsing failed; response should not be used for clinical decisions."
            )
