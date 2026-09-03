import os
import sys
import json
import logging
from typing import Dict, Any, Optional

from ai.schemas.health_analysis import NirogXDatasetExample
from ai.inference.medgemma import MedGemmaInferenceEngine
from ai.evaluation.metrics import MultiTierMetrics
from ai.rag.retriever import MedicalRAGRetriever
from ai.safety.rules import SafetyEngine
from ai.safety.sanitizer import OutputSanitizer

logger = logging.getLogger(__name__)

def run_benchmark(
    gold_cases_path: str,
    inference_engine: MedGemmaInferenceEngine,
    safety_engine: Optional[SafetyEngine] = None,
    sanitizer: Optional[OutputSanitizer] = None,
    rag_retriever: Optional[MedicalRAGRetriever] = None,
    output_report_path: str = None
) -> Dict[str, Any]:
    """
    Executes the multi-tiered benchmark evaluation harness over the 100 gold cases with RAG knowledge grounding.
    """
    if not os.path.exists(gold_cases_path):
        raise FileNotFoundError(f"Gold evaluation file not found at: {gold_cases_path}")

    with open(gold_cases_path, "r", encoding="utf-8") as f:
        raw_cases = json.load(f)

    gold_cases = [NirogXDatasetExample.model_validate(c) for c in raw_cases]
    metrics = MultiTierMetrics()
    case_results = []

    print(f"Starting multi-tier evaluation benchmark over {len(gold_cases)} gold cases...")
    for idx, case in enumerate(gold_cases):
        grounded_guidelines = None
        if rag_retriever:
            retrieved = rag_retriever.retrieve_guidelines(case.input, top_k=2)
            grounded_guidelines = rag_retriever.format_grounded_context(retrieved)

        output, latency_ms = inference_engine.generate_analysis(
            case.input,
            retrieved_guidelines=grounded_guidelines
        )
        res = metrics.evaluate_case(
            case,
            output,
            latency_ms,
            safety_engine=safety_engine,
            sanitizer=sanitizer
        )
        case_results.append(res)
        if (idx + 1) % 25 == 0 or (idx + 1) == len(gold_cases):
            print(f"Evaluated {idx + 1}/{len(gold_cases)} cases...")

    summary = metrics.compute_summary()
    full_report = {
        "model_path": inference_engine.model_name_or_path,
        "adapter_path": inference_engine.adapter_path,
        "runtime_type": inference_engine.runtime_type,
        "is_mock_fallback": inference_engine.is_mock_fallback,
        "rag_kb_version": rag_retriever.kb_version if rag_retriever else "none",
        "dataset_evaluated": gold_cases_path,
        "summary": summary,
        "detailed_results": case_results
    }

    if output_report_path:
        os.makedirs(os.path.dirname(output_report_path), exist_ok=True)
        with open(output_report_path, "w", encoding="utf-8") as f:
            json.dump(full_report, f, indent=2)
        print(f"Saved multi-tier evaluation report to: {output_report_path}")

    return full_report
