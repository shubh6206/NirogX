import logging
from typing import Dict, Any, Tuple
from ai.schemas.patient_context import PatientContext
from ai.schemas.health_analysis import ConfidenceLevelEnum

logger = logging.getLogger(__name__)

class ConfidenceCalibrator:
    """
    Deterministic clinical evidence calibration engine.
    Ensures confidence matches available evidence rather than arbitrary LLM generation.
    """
    def calibrate(self, context: PatientContext, is_biologically_implausible: bool = False) -> Tuple[ConfidenceLevelEnum, str]:
        if is_biologically_implausible:
            return (
                ConfidenceLevelEnum.NOT_ASSESSABLE,
                "Confidence is NOT_ASSESSABLE due to contradictory or biologically implausible sensor readings."
            )

        # Count evidence streams
        has_vitals = bool(context.health_metrics and len(context.health_metrics) > 0)
        has_labs = bool(context.lab_results and len(context.lab_results) > 0)
        has_report = bool(context.report_text and len(context.report_text.strip()) > 20)
        has_image = bool(context.image_reference)
        has_history = bool(context.medical_history and len(context.medical_history) > 0)
        symptom_count = len(context.symptoms)

        evidence_sources = sum([has_vitals, has_labs, has_report, has_image, has_history])

        # Calibration Rules
        if evidence_sources >= 2 and (has_labs or has_report or has_vitals):
            return (
                ConfidenceLevelEnum.HIGH,
                "High confidence grounded across multi-source objective clinical and biometric records."
            )
        elif evidence_sources == 1 or symptom_count >= 2:
            return (
                ConfidenceLevelEnum.MODERATE,
                "Moderate confidence based on partial evidence; supplementary clinical confirmation advised."
            )
        elif symptom_count == 1 or bool(context.question):
            return (
                ConfidenceLevelEnum.LOW,
                "Low confidence due to sparse single-stream input without corroborated vitals or lab verification."
            )
        else:
            return (
                ConfidenceLevelEnum.NOT_ASSESSABLE,
                "Insufficient clinical context provided for meaningful assessment."
            )
