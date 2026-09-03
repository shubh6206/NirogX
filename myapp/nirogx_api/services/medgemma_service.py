import os
import uuid
import logging
from typing import Dict, Any, Tuple, Optional

from ai.schemas.patient_context import PatientContext
from ai.schemas.health_analysis import HealthAnalysisRequest, HealthAnalysisOutput
from ai.inference.medgemma import MedGemmaInferenceEngine
from ai.inference.profiler import LatencyProfiler
from ai.rag.retriever import MedicalRAGRetriever
from ai.safety.rules import SafetyEngine
from ai.safety.sanitizer import OutputSanitizer
from ai.safety.validator import SafetyOutputValidator
from ai.safety.confidence_calibrator import ConfidenceCalibrator
from ai.safety.audit_logger import PrivacyAuditLogger

logger = logging.getLogger(__name__)

class MedGemmaService:
    def __init__(self, remote_api_url: Optional[str] = None, evaluation_mode: Optional[bool] = None):
        adapter_path = os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
            "models", "nirogx-medgemma-4b-v0.1"
        )
        self.inference_engine = MedGemmaInferenceEngine(
            model_name_or_path="google/medgemma-1.5-4b-it",
            adapter_path=adapter_path if os.path.exists(adapter_path) else None,
            remote_api_url=remote_api_url or os.getenv("MEDGEMMA_REMOTE_URL"),
            use_fallback_if_unavailable=True,
            evaluation_mode=evaluation_mode
        )
        self.rag_retriever = MedicalRAGRetriever()
        self.safety_engine = SafetyEngine()
        self.sanitizer = OutputSanitizer()
        self.validator = SafetyOutputValidator()
        self.calibrator = ConfidenceCalibrator()
        self.audit_logger = PrivacyAuditLogger()

    def analyze_health(self, request: HealthAnalysisRequest) -> Tuple[HealthAnalysisOutput, Dict[str, Any]]:
        """
        Production Clinical Intelligence Pipeline:
        Input -> Gate 1 Safety -> Medical RAG Grounding -> MedGemma -> Gate 2 Sanitizer -> Schema Validation -> Telemetry.
        """
        profiler = LatencyProfiler()
        request_id = f"req_{uuid.uuid4().hex[:12]}"
        
        # 1. Input Normalization
        profiler.start_phase("preprocessing")
        if request.patient_context:
            context = request.patient_context
        else:
            context = PatientContext(
                symptoms=request.symptoms,
                health_metrics=request.health_metrics,
                lab_results=request.lab_results,
                report_text=request.medical_report or "",
                image_reference=request.image,
                question=request.question or ""
            )
        profiler.end_phase()

        # 2. GATE 1: Deterministic Pre-Inference Safety Triage
        profiler.start_phase("gate1_safety")
        is_urgent, urgent_flags = self.safety_engine.check_emergency_signals(context)
        is_rx_violation, rx_flag = self.safety_engine.check_prescription_boundaries(context)
        is_plausible, plausibility_errors = self.safety_engine.validate_biological_plausibility(context)
        profiler.end_phase()

        # 3. Medical RAG Grounding
        profiler.start_phase("rag_retrieval")
        retrieved_guidelines_list = self.rag_retriever.retrieve_guidelines(context, top_k=2)
        grounded_guidelines_str = self.rag_retriever.format_grounded_context(retrieved_guidelines_list)
        profiler.end_phase()

        # 4. MedGemma Reasoning Inference
        profiler.start_phase("model_inference")
        raw_output, _ = self.inference_engine.generate_analysis(
            context,
            retrieved_guidelines=grounded_guidelines_str
        )
        profiler.end_phase()

        # 5. Schema Validation & Safe Fallback
        profiler.start_phase("schema_validation")
        validated_output = self.validator.validate_and_fallback(raw_output)
        validation_passed = (validated_output.confidence != "NOT_ASSESSABLE" and not raw_output.get("json_parse_error", False))
        profiler.end_phase()

        # 6. Inject Deterministic Risk Flags & Evidence Grounding
        profiler.start_phase("gate2_safety")
        if is_urgent:
            validated_output.urgent_attention = True
            for flag in urgent_flags:
                if not any(f.category == flag.category for f in validated_output.risk_flags):
                    validated_output.risk_flags.insert(0, flag)

        if is_rx_violation and rx_flag:
            if not any(f.category == rx_flag.category for f in validated_output.risk_flags):
                validated_output.risk_flags.insert(0, rx_flag)

        if not is_plausible:
            for p_err in plausibility_errors:
                validated_output.missing_information.append(f"Verification required: {p_err}")

        # Deterministic Evidence Calibration
        calibrated_conf, conf_reason = self.calibrator.calibrate(
            context=context,
            is_biologically_implausible=(not is_plausible)
        )
        validated_output.confidence = calibrated_conf
        if conf_reason:
            validated_output.uncertainty = f"{validated_output.uncertainty} {conf_reason}".strip()

        # GATE 2: Sanitization & Action Deduplication
        final_output = self.sanitizer.sanitize(validated_output, force_urgent=is_urgent)
        profiler.end_phase()

        latency_breakdown = profiler.get_breakdown()

        # 7. Privacy-Preserving Telemetry Logging (Zero PII)
        self.audit_logger.log_inference_event(
            model_version="0.3.0",
            kb_version=self.rag_retriever.kb_version,
            runtime_type=self.inference_engine.runtime_type,
            latency_breakdown=latency_breakdown,
            is_urgent=is_urgent,
            confidence_level=str(calibrated_conf.value if hasattr(calibrated_conf, 'value') else calibrated_conf),
            validation_passed=validation_passed,
            request_id=request_id
        )

        metadata = {
            "request_id": request_id,
            "model": "nirogx-medgemma-4b",
            "model_version": "0.3.0",
            "kb_version": self.rag_retriever.kb_version,
            "runtime_type": self.inference_engine.runtime_type,
            "retrieved_guidelines_count": len(retrieved_guidelines_list),
            "latency_breakdown_ms": latency_breakdown,
            "latency_ms": latency_breakdown.get("total_api_latency_ms", 0.0),
            "total_latency_ms": latency_breakdown.get("total_api_latency_ms", 0.0),
            "inference_latency_ms": latency_breakdown.get("model_inference_ms", 0.0),
            "is_mock_fallback": self.inference_engine.is_mock_fallback,
            "confidence_calibrated": True
        }

        return final_output, metadata

# Singleton instance for FastAPI dependency injection
medgemma_service_instance = MedGemmaService()
