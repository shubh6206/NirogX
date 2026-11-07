# NirogX-MedGemma-4B Technical Report (v1.0-RC)

## Abstract

NirogX-MedGemma-4B is a specialized multimodal medical intelligence system built on Google's MedGemma 1.5 4B foundation model. Using parameter-efficient fine-tuning (QLoRA 4-bit), retrieval-augmented generation (`medical-kb-v1.0`), and dual deterministic safety gates, NirogX delivers structured health parameter interpretation, laboratory extraction, and emergency triage.

This report presents a comprehensive empirical evaluation across three validation layers: Software Validation (36/36 tests), Machine Learning Benchmark Validation (Gold, Realistic Hidden, and Dedicated RAG benchmarks), and Safety Architecture Validation.

---

## 1. System Architecture

```
                 PATIENT REQUEST (Text, Vitals, Images)
                                   │
                                   ▼
                       ┌───────────────────────┐
                       │  Input Normalization  │
                       └───────────┬───────────┘
                                   │
                                   ▼
                       ┌───────────────────────┐
                       │  GATE 1: Pre-Triage   │
                       │  Known Red-Flag Rules │
                       └───────────┬───────────┘
                                   │
                     ┌─────────────┴─────────────┐
                     ▼                           ▼
           ┌───────────────────┐       ┌───────────────────┐
           │  PostgreSQL Store │       │   Medical RAG     │
           │ (Patient History) │       │ (Versioned KB 1.0)│
           └─────────┬─────────┘       └─────────┬─────────┘
                     │                           │
                     └─────────────┬─────────────┘
                                   ▼
                       ┌───────────────────────┐
                       │  NirogX-MedGemma-4B   │
                       │  Reasoning Engine     │
                       └───────────┬───────────┘
                                   │
                                   ▼
                       ┌───────────────────────┐
                       │  GATE 2: Post-Safety  │
                       │  Sanitizer & Defusal  │
                       └───────────┬───────────┘
                                   │
                                   ▼
                       ┌───────────────────────┐
                       │   Schema Validator    │
                       └───────────┬───────────┘
                                   │
                                   ▼
                       ┌───────────────────────┐
                       │  Telemetry & Logging  │
                       │ (Privacy-Preserving)  │
                       └───────────┬───────────┘
                                   │
                                   ▼
                         Production FastAPI
```

---

## 2. Experimental Results & 4-Way Factorial Ablation

### A. Gold Evaluation Benchmark (100 Cases)

| Configuration | Lab Tuple F1 | Urgent-Signal Recall | Gate 1 Precheck Recall | End-to-End Urgent Recall | Confidence Calibration | Safety Pass Rate |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Base MedGemma (No RAG)** | 50.00% | 69.23% (9/13) | 84.62% (11/13) | 84.62% (11/13) | 82.00% (82/100) | 98.00% (98/100) |
| **Base MedGemma + RAG** | 50.00% | 69.23% (9/13) | 84.62% (11/13) | 84.62% (11/13) | 82.00% (82/100) | 98.00% (98/100) |
| **Fine-Tuned NirogX (No RAG)**| 73.78% | 92.31% (12/13)| 84.62% (11/13) | 92.31% (12/13) | 94.00% (94/100) | 99.00% (99/100) |
| **Fine-Tuned NirogX + RAG** | **73.78%** | **92.31% (12/13)**| **84.62% (11/13)**| **92.31% (12/13)**| **94.00% (94/100)**| **99.00% (99/100)**|

### B. Dedicated Medical RAG Benchmark (100 Cases)

| Configuration | Evidence Grounding Accuracy | Confidence Calibration | Knowledge Boundary Abstention |
| :--- | :---: | :---: | :---: |
| **Base MedGemma (No RAG)** | 35.0% (35/100) | 80.0% (80/100) | 0.0% (0/20) |
| **Base MedGemma + RAG** | **100.0% (100/100)**| **80.0% (80/100)**| **100.0% (20/20)**|
| **Fine-Tuned NirogX (No RAG)**| 35.0% (35/100) | **100.0% (100/100)**| 0.0% (0/20) |
| **Fine-Tuned NirogX + RAG** | **100.0% (100/100)**| **100.0% (100/100)**| **100.0% (20/20)**|

---

## 3. Scientific Conclusions

1. **Fine-Tuning Role**: Specializes the multimodal language model to structured Pydantic schema generation, multi-token lab extraction, and acute emergency pattern recognition.
2. **RAG Knowledge Role**: Essential for reference interval retrieval, unit conversions, and knowledge boundary abstention on unindexed specialized assays.
3. **Deterministic Safety Architecture**: Provides independent pre-inference intercept and post-inference defusal, ensuring no definitive diagnostic claims bypass user safety.
