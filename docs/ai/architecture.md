# NirogX Medical Intelligence Architecture (NirogX-MedGemma-4B)

## 1. System Overview

NirogX-MedGemma-4B is a specialized multimodal AI intelligence layer integrated into the NirogX healthcare ecosystem. Rather than serving as an autonomous medical authority, it functions as a preliminary clinical decision-support and structured health summarization engine.

```
┌────────────────────────────────────────────────────────┐
│               Flutter App / Web Frontend               │
└───────────────────────────┬────────────────────────────┘
                            │ (HTTPS / JSON)
                            ▼
┌────────────────────────────────────────────────────────┐
│            FastAPI Gateway (nirogx_api)                │
│  - POST /api/v1/health/analyze                         │
│  - Authentication & PostgreSQL Health Record Store     │
└──────────────┬────────────────────────────┬────────────┘
               │                            │
               ▼                            ▼
┌───────────────────────────────┐ ┌──────────────────────┐
│ Deterministic Safety Pre-Check│ │ Input Normalization  │
│ - Emergency Triage Rules      │ │ - Vitals & Biometrics│
│ - Prescription Boundary Check │ │ - Lab Report OCR     │
│ - Biological Plausibility     │ │ - Patient History    │
└──────────────┬────────────────┘ └──────────┬───────────┘
               │                             │
               └──────────────┬──────────────┘
                              ▼
┌────────────────────────────────────────────────────────┐
│       NirogX-MedGemma-4B Model Service Layer           │
│  - Base Foundation: MedGemma 1.5 4B (Text + Vision)   │
│  - Specialized Adapters: QLoRA Fine-Tuned Weights     │
│  - Prompt Orchestration & Few-Shot Instruction        │
└─────────────────────────────┬──────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────┐
│        Deterministic Safety & Sanitization Layer       │
│  - Pydantic Schema Validation (≥98% Target)            │
│  - Emergency Flag Enforcement & Escalation             │
│  - Definitive Diagnosis Defusal                        │
│  - Centralized Medical Disclaimer Injection            │
└─────────────────────────────┬──────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────┐
│         Structured Clinical Intelligence Output        │
└────────────────────────────────────────────────────────┘
```

## 2. Core Principles
1. **Foundation First**: Grounded on Google's MedGemma 1.5 4B multimodal medical foundation.
2. **Behavioral Specialization**: Fine-tuning specializes formatting, extraction, and uncertainty communication without attempting to memorize medical facts into model weights.
3. **External Deterministic Safety**: All critical escalation rules (chest pain, stroke signs, extreme vitals, prescription requests) are enforced deterministically outside the LLM.
4. **Zero Regressions**: Added in complete isolation under `myapp/nirogx_api/ai/`, leaving existing user authentication, biometric synchronization, and calculator routes intact.
