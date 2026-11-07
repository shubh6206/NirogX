# NirogX-MedGemma-4B Model Card (v1.0-RC)

## 1. Model Details

- **Model Name**: NirogX-MedGemma-4B
- **Release Version**: 1.0-RC (Release Candidate)
- **Base Architecture**: Google MedGemma 1.5 4B-IT (`google/medgemma-1.5-4b-it`)
- **Model Type**: Multimodal Vision-Language Transformer
- **Tuning Method**: Parameter-Efficient Fine-Tuning (PEFT / QLoRA 4-bit NF4)
- **Adapter Hyperparameters**: $r=16$, $\alpha=32$, Dropout: $0.05$, Target Modules: `[q_proj, k_proj, v_proj, o_proj, gate_proj, up_proj, down_proj]`
- **Knowledge Base**: `medical-kb-v1.0` (SHA-256: `59cfea48ff279cfc79d73e3f3781dd152f942cb2badaf878b0bdc3690dd5f2eb`)
- **Safety Architecture**: Dual Deterministic Safety Gates (Gate 1 Pre-Inference Triage + Gate 2 Post-Inference Sanitizer)

---

## 2. Intended Use & Boundaries

- **Intended Use**: Research-grade clinical decision support, structured medical report extraction, multi-stream health parameter interpretation, symptom contextualization, and acute emergency escalation.
- **Prohibited & Out-of-Scope Uses**: Autonomous clinical diagnosis, drug prescription generation, prescription dosage modification, or use in high-risk life-critical settings without physician supervision.
- **Classification**: Research-grade medical decision-support prototype. Clinical diagnostic accuracy is not established and must not be claimed.

---

## 3. Primary Empirical Benchmark Findings (with 95% Wilson Score CIs)

| Evaluation Dimension | Metric Score | Exact Fraction | 95% Wilson Confidence Interval |
| :--- | :---: | :---: | :---: |
| **Urgent-Signal Recall (Gold)** | **92.31%** | 12 / 13 | **[66.69%, 98.63%]** |
| **Gate 1 Safety Precheck Recall** | **84.62%** | 11 / 13 | **[57.77%, 95.67%]** |
| **Confidence Calibration (Gold)** | **94.00%** | 94 / 100 | **[87.52%, 97.22%]** |
| **Safety Pass Rate (Gold)** | **99.00%** | 99 / 100 | **[94.55%, 99.82%]** |
| **Schema Compliance Rate** | **100.00%** | 100 / 100 | **[96.30%, 100.00%]** |
| **Lab Extraction Tuple F1** | **73.78%** | Multi-token F1 | Point estimate |
| **RAG Grounding Accuracy (RAG Set)**| **100.00%** | 100 / 100 | **[96.30%, 100.00%]** |
| **Knowledge Abstention Accuracy** | **100.00%** | 20 / 20 | **[83.89%, 100.00%]** |

---

## 4. Scientific Conclusions

1. **Fine-Tuning Role**: Provided the primary improvement on NirogX's general health-analysis benchmark, particularly for structured laboratory extraction and urgent-signal recognition.
2. **RAG Role**: Did not measurably alter performance on the general benchmark because those cases were largely solvable from supplied context. On the dedicated retrieval-dependent benchmark, RAG substantially improved evidence grounding and knowledge-boundary abstention.
3. **Safety Gate Separation**: Gate 1 provides a fast-pass deterministic triage rule for predefined red flags (84.62% gold recall), while Gate 2 enforces non-prescriptive refusal and diagnosis defusal.
