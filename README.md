# NirogX: Multimodal Medical AI Decision Support & Clinical Intelligence Platform

[![Release](https://img.shields.io/badge/Release-v1.0--RC-blue.svg)](release/NirogX-MedGemma-4B-v1.0-RC)
[![Base Model](https://img.shields.io/badge/Base%20Model-Google%20MedGemma%201.5%204B-green.svg)](https://huggingface.co/google/medgemma-1.5-4b-it)
[![Fine-Tuning](https://img.shields.io/badge/Fine--Tuning-QLoRA%204--bit%20NF4-orange.svg)](models/nirogx-medgemma-4b-v0.1/)
[![Safety](https://img.shields.io/badge/Safety-Dual--Gate%20Deterministic-red.svg)](docs/safety.md)
[![Verification](https://img.shields.io/badge/Integrity-SHA--256%20Verified-brightgreen.svg)](checksums/SHA256SUMS)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

> **"Rigorous Signals. Grounded Evidence. Safe Human Escalation."**  
> *A clinical decision-support and health monitoring platform built on Google's MedGemma foundation architecture, designed for structured lab extraction, multi-stream vital trend interpretation, and deterministic emergency triage.*

---

## 1. System Overview

**NirogX** is a multimodal clinical intelligence platform that bridges personal wearable telemetries, electronic health records, and laboratory diagnostic reports into structured clinical decision support.

Unlike generic conversational LLMs that risk medical hallucinations or prescriptive boundary violations, NirogX employs a **Dual-Gate Safety Architecture** combined with **Retrieval-Augmented Generation (RAG)** and parameter-efficient domain adaptation:

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
                        │  GATE 1: Pre-Triage   │  ◄── Deterministic red-flag rules
                        │  Known Red-Flag Rules │      (ACS, Stroke FAST, Panic vitals)
                        └───────────┬───────────┘
                                    │
                      ┌─────────────┴─────────────┐
                      ▼                           ▼
            ┌───────────────────┐       ┌───────────────────┐
            │  PostgreSQL Store │       │    Medical RAG    │
            │ (Patient History) │       │ (Versioned KB 1.0)│
            └─────────┬─────────┘       └─────────┬─────────┘
                      │                           │
                      └─────────────┬─────────────┘
                                    ▼
                        ┌───────────────────────┐
                        │  NirogX-MedGemma-4B   │  ◄── QLoRA (r=16, α=32, 4-bit)
                        │  Reasoning Engine     │      Google MedGemma 1.5 4B-IT
                        └───────────┬───────────┘
                                    │
                                    ▼
                        ┌───────────────────────┐
                        │  GATE 2: Post-Safety  │  ◄── Strips autonomous diagnoses,
                        │  Sanitizer & Defusal  │      enforces non-prescriptive rules
                        └───────────┬───────────┘
                                    │
                                    ▼
                        ┌───────────────────────┐
                        │   Schema Validator    │  ◄── 100% Pydantic strict output
                        └───────────┬───────────┘
                                    │
                                    ▼
                        ┌───────────────────────┐
                        │  Telemetry & Logging  │  ◄── Privacy-preserving anonymized
                        │ (Privacy-Preserving)  │      audit traces
                        └───────────┬───────────┘
                                    │
                                    ▼
                         Clinical Client / App
```

---

## 2. Core Pillars & Capabilities

### 🩺 1. MedGemma 1.5 4B Clinical Adaptation
* **Base Architecture**: Google MedGemma 1.5 4B-IT (`google/medgemma-1.5-4b-it`).
* **PEFT / QLoRA**: 4-bit NormalFloat (NF4) quantization, double quantization, rank $r=16$, scale $\alpha=32$, targeting `[q_proj, k_proj, v_proj, o_proj, gate_proj, up_proj, down_proj]`.
* **Zero Cloud Leakage**: Local CPU/GPU execution pathways with offline deterministic fallbacks.

### 🛡️ 2. Dual Deterministic Safety Gates
* **Gate 1 (Pre-Inference Triage)**: Deterministic evaluation prior to LLM inference scanning for acute emergencies:
  * Acute Coronary Syndrome (ACS equivalents)
  * Acute Stroke (FAST clinical criteria)
  * Diabetic Ketoacidosis (DKA) & Sepsis vitals
  * Extreme physiological panic ranges (HR > 160 bpm, SpO₂ < 85%, SBP > 200 mmHg)
* **Gate 2 (Post-Inference Sanitizer)**: Defuses unhedged diagnostic pronouncements, strips medication dosages or prescriptions, and appends mandatory clinical referral guidance.

### 📚 3. Medical RAG (`medical-kb-v1.0`)
* **Grounded Reference Ranges**: Verifies multi-assay laboratory thresholds against authoritative reference intervals (SHA-256: `59cfea48...`).
* **Knowledge Abstention**: Explicitly abstains on out-of-domain medical queries rather than generating speculative answers.

### 📱 4. Multi-Platform Cross-Client Experience
* **Mobile Client**: Flutter 3.x, Material 3, SQLite local persistence (`sqflite`), Android Health Connect & iOS HealthKit integration.
* **Backend API**: High-performance FastAPI backend, Pydantic v2 schemas, automated latency profiling, and role-based data partitioning.

---

## 3. Empirical Benchmark Summary (95% Wilson CIs)

Comprehensive empirical validation across **36/36 passing software tests** and **300 benchmark cases**:

| Metric | Score | Exact Ratio | 95% Wilson Score CI |
| :--- | :---: | :---: | :---: |
| **Urgent-Signal Recall (Gold)** | **92.31%** | 12 / 13 | `[66.69%, 98.63%]` |
| **Gate 1 Safety Precheck Recall** | **84.62%** | 11 / 13 | `[57.77%, 95.67%]` |
| **Confidence Calibration (Gold)** | **94.00%** | 94 / 100 | `[87.52%, 97.22%]` |
| **Safety Pass Rate (Gold)** | **99.00%** | 99 / 100 | `[94.55%, 99.82%]` |
| **Schema Compliance Rate** | **100.00%** | 100 / 100 | `[96.30%, 100.00%]` |
| **RAG Grounding Accuracy (RAG Set)** | **100.00%** | 100 / 100 | `[96.30%, 100.00%]` |
| **Knowledge Abstention Accuracy** | **100.00%** | 20 / 20 | `[83.89%, 100.00%]` |

*See [`docs/technical_report.md`](docs/technical_report.md) and [`docs/model_card.md`](docs/model_card.md) for full statistical derivations.*

---

## 4. Repository Structure

```
Nirogx/
├── myapp/
│   ├── nirogx_api/              # FastAPI Clinical Intelligence Backend
│   │   ├── ai/                  # MedGemma inference, RAG, safety gates, schemas
│   │   ├── services/            # Health scoring, vitals & database synchronization
│   │   └── tests/               # 36 unit and integration test suites
│   └── nirogx_app/              # Flutter Cross-Platform Mobile Client
│       └── lib/                 # Dart UI screens, SQLite persistence, and providers
├── datasets/                    # Versioned Benchmark & Training Datasets
│   ├── gold/                    # 100 Gold evaluation cases & synthetic doc images
│   ├── hidden_eval/             # 100 Out-of-distribution evaluation cases
│   ├── rag_benchmark/           # 100 RAG eval cases & 100 RAG holdout queries
│   └── metadata/                # 4-way ablation matrices and audit outputs
├── models/                      # Fine-Tuned PEFT Adapters & Hyperparameters
│   └── nirogx-medgemma-4b-v0.1/ # adapter_config.json, training_metrics.json
├── training/                    # ML Pipeline & Reproducibility Suite
│   ├── train_qlora.py           # 4-bit QLoRA fine-tuning script
│   ├── run_ablation_study.py    # 4-way ablation study runner
│   ├── evaluate.py              # Benchmark evaluation harnesses
│   └── reproduce_rc_benchmark.py # Automated master reproduction script
├── evaluation/                  # Empirical Benchmark Result Files (JSON)
├── release/                     # Frozen Release Distribution Package (v1.0-RC)
├── checksums/                   # Cryptographic SHA-256 Verification Manifests
└── docs/                        # Complete Technical & Scientific Documentation
    ├── technical_report.md      # Full v1.0-RC technical report
    ├── model_card.md            # MedGemma 4B model card
    ├── safety.md                # Safety architecture & governance policies
    ├── reproducibility.md       # Master clean-environment reproduction guide
    └── ai/                      # 17 numbered RC audit & benchmark reports
```

---

## 5. Quick Start & Execution

### 1. Prerequisites
* Python 3.11+
* Flutter 3.x / Dart 3.x (for mobile application)
* NVIDIA GPU (16GB+ VRAM) for 4-bit MedGemma GPU inference *(CPU fallback automatically supported)*

### 2. Run Backend API Server
```powershell
# Navigate to backend API directory
cd myapp/nirogx_api

# Install dependencies
pip install -r requirements.txt

# Start FastAPI server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```
Interactive Swagger API documentation will be available at: `http://localhost:8000/docs`

### 3. Run Automated Test Suite
```powershell
# Execute all 36 test modules
pytest myapp/nirogx_api/tests -v
```

### 4. Reproduce v1.0-RC Benchmarks
```powershell
# Run the automated benchmark verification pipeline
python training/reproduce_rc_benchmark.py
```

### 5. Verify Cryptographic Integrity
```powershell
# Verify SHA-256 dataset and artifact checksums
Get-FileHash datasets/gold/gold_evaluation_cases.json
Get-FileHash datasets/hidden_eval/hidden_evaluation_cases.json
Get-FileHash datasets/rag_benchmark/rag_evaluation_cases.json
```

---

## 6. Safety & Clinical Governance Disclaimer

> [!IMPORTANT]
> **NirogX is a research-grade clinical decision-support prototype.**  
> It is strictly designed to assist qualified healthcare professionals and structured wellness tracking. It does **not** provide autonomous clinical diagnoses, does **not** issue medical prescriptions, and must never replace clinical judgment in acute life-critical emergencies.

---

## 7. License

Distributed under the **Apache License 2.0**. See [`LICENSE`](LICENSE) for details.
