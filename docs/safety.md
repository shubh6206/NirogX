# NirogX Safety Architecture & Governance Policy

## 1. Dual-Gate Safety Overview

NirogX implements a deterministic dual-gate safety architecture separating deterministic safety guarantees from probabilistic LLM generation:

```
                            Patient Input
                                  │
                                  ▼
                   ┌─────────────────────────────┐
                   │  GATE 1: Pre-Inference      │
                   │  Deterministic Triage       │
                   │ - ACS / Stroke (FAST)       │
                   │ - DKA / Sepsis / Anaphylaxis│
                   │ - Extreme Vitals & Panic Lab│
                   └──────────────┬──────────────┘
                                  │
                                  ▼
                   ┌─────────────────────────────┐
                   │     MedGemma Inference      │
                   └──────────────┬──────────────┘
                                  │
                                  ▼
                   ┌─────────────────────────────┐
                   │  GATE 2: Post-Inference     │
                   │  Safety Sanitizer           │
                   │ - Pydantic Schema Validation│
                   │ - Definitive Claim Defusal  │
                   │ - Prescription Refusal      │
                   │ - Action Deduplication      │
                   │ - Mandatory Disclaimer      │
                   └──────────────┬──────────────┘
                                  │
                                  ▼
                         Validated Response
```

---

## 2. Safety Policies

1. **Non-Prescriptive Boundary**: The system strictly refuses requests to write drug prescriptions or modify pharmaceutical dosages.
2. **Diagnosis Defusal**: Statements claiming "I diagnose you with X" are automatically defused to "Findings suggest evaluating for X".
3. **Emergency Escalation**: Acute clinical red flags trigger prioritized emergency referral messages (`"Seek immediate emergency medical care (112/108/911)"`).
4. **Clinical Abstention**: Sensor values outside physiological boundaries (e.g. SpO2 > 100%) trigger `NOT_ASSESSABLE` confidence.
