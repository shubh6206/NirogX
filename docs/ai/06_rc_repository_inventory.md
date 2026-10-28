# 06. NirogX-MedGemma-4B Release Candidate Repository Inventory

## 1. Executive Summary

This document establishes the verified inventory of all components, models, adapters, datasets, evaluation scripts, and safety modules across the NirogX repository (`Nirogx/`) as part of the Phase 0 RC Freeze Gate audit.

---

## 2. Component Inventory Matrix

| Area | Component / Path | Primary Role | Status / Observation |
| :--- | :--- | :--- | :--- |
| **Model Engine** | `myapp/nirogx_api/ai/inference/medgemma.py` | Core MedGemma 1.5 4B-IT inference engine | Supports HuggingFace Transformers, 4-bit BitsAndBytes, PEFT adapter loading, with deterministic simulated fallback on CPU-only environments. |
| **PEFT Adapter** | `models/nirogx-medgemma-4b-v0.1/` | QLoRA fine-tuned adapter configuration & metadata | Contains `adapter_config.json` ($r=16$, $\alpha=32$, 4-bit NF4) and `training_metrics.json`. Weights binary is linked via external HuggingFace repo. |
| **Inference Pipeline** | `myapp/nirogx_api/ai/inference/` | Prompts, profiling, multimodal document processing | Includes `prompts.py` (system & task prompts), `profiler.py` (per-stage microsecond latency tracking), `multimodal_processor.py` (OCR cleanup & corruption detection). |
| **Safety Gate 1** | `myapp/nirogx_api/ai/safety/rules.py` | Deterministic pre-inference emergency triage | Scans for ACS equivalents, acute stroke, panic lab values, extreme vitals prior to LLM generation. |
| **Safety Gate 2** | `myapp/nirogx_api/ai/safety/sanitizer.py` | Deterministic post-inference output defusal | Defuses definitive diagnoses, strips drug prescriptions, deduplicates emergency referrals, and injects clinical disclaimers. |
| **Confidence & Telemetry**| `myapp/nirogx_api/ai/safety/` | Calibration & Privacy Audit Logger | `confidence_calibrator.py` calculates evidence-count calibration; `audit_logger.py` logs anonymized execution traces. |
| **Medical RAG** | `myapp/nirogx_api/ai/rag/` | Versioned guideline retrieval (`medical-kb-v1.0`) | `retriever.py` queries `knowledge_base.json` (SHA-256: `59cfea...`) for reference intervals, panic cutoffs, and clinical guidelines. |
| **Gold Benchmark** | `datasets/gold/gold_evaluation_cases.json` | 100 immutable gold cases | SHA-256: `bb911e180269...`. Baseline vs FT benchmark suite. |
| **Hard Hidden Eval**| `datasets/hidden_eval/hidden_evaluation_cases.json` | 100 out-of-distribution cases | SHA-256: `a023fa861c2f...`. Tests novel assays, sensor anomalies, and non-emergent confounders. |
| **Dedicated RAG Benchmark** | `datasets/rag_benchmark/rag_evaluation_cases.json` | 100 retrieval-dependent cases | SHA-256: `9a4548464498...`. Tests reference-range lookup, unit conversions, guideline grounding, lore defusal, and knowledge abstention. |
| **RAG Holdout Challenge** | `datasets/rag_benchmark/rag_holdout_cases.json` | 100 holdout retrieval cases | SHA-256: `7efab96b6546...`. Independent holdout queries without expected answer leakage. |
| **Evaluation Suite** | `training/` | Benchmarking and statistical validation | `reproduce_rc_benchmark.py`, `run_ablation_study.py`, `evaluate_rag_benchmark.py`, and `evaluate.py`. |
| **Automated Tests** | `myapp/nirogx_api/tests/` | 36 unit and integration test modules | Complete unit tests covering schemas, profiler, RAG retriever, multimodal vision processor, privacy logger, and FastAPI endpoints. |
| **Release Artifact**| `release/NirogX-MedGemma-4B-v1.0-RC/` | Literal frozen release distribution | Physical tree with `model/`, `benchmarks/`, `results/`, `documentation/`, and `SHA256SUMS`. |

---

## 3. Stale / Legacy Files Identified

- `walkthrough1`, `implementation_plan1`, `implementation_plan 0.9` in root directory: Legacy sprint artifacts.
- Note on Model Weights: In this Windows CPU development environment, `torch` and GPU CUDA drivers are not installed in `venv_win`, so `medgemma.py` switches to `runtime_provenance: "simulated_local_engine"`. Genuine GPU execution requires deployment on an NVIDIA T4/A10G environment.
