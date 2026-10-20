# 00. NirogX 10-Point Data Leakage & Methodological Audit

## 1. Executive Summary

This formal 10-point audit inspects the training sets (`train.json`, synthetic targeted sets), evaluation benchmarks (`gold_evaluation_cases.json`, `hidden_evaluation_cases.json`, `rag_evaluation_cases.json`, `rag_holdout_cases.json`), prompting pipelines, and scoring code to establish that benchmark evaluations are completely free from data contamination, label leakage, and heuristic cheating.

---

## 2. 10-Point Audit Verification Matrix

| # | Audit Vector | Investigation Method & Evidence | Audit Status | Audit Details & Remediations |
| :-: | :--- | :--- | :-: | :--- |
| **1** | **Hidden cases absent from training data** | Automated SHA-256 hashing and case ID cross-referencing between `datasets/hidden_eval/` and `datasets/pilot/` / `targeted/`. | 🟢 **PASS** | Zero exact case matches, zero identifier overlap (`NX-HARD-*` vs `NX-TR-*`). |
| **2** | **Gold cases absent from training data** | Cross-split set difference on patient symptoms and lab result text. | 🟢 **PASS** | Gold cases (`NX-GOLD-*`) were created as an immutable benchmark prior to training generation and strictly sequestered. |
| **3** | **Expected outputs not inserted into prompts** | Line-by-line inspection of `prompts.py` (`format_patient_context_prompt`) and `evaluate.py`. | 🟢 **PASS** | Prompt builder receives solely `PatientContext` (`symptoms`, `health_metrics`, `report_text`, `question`). `case.expected_output` is never serialized into input. |
| **4** | **Labels not encoded in metadata** | Inspected `PatientContext.model_dump()` serialized into LLM inference calls. | 🟢 **PASS** | No urgency boolean, severity enum, or target finding labels exist within the input context or metadata payload. |
| **5** | **Benchmark answers not hardcoded into evaluation** | Inspected `ai/inference/medgemma.py`, `ai/evaluation/benchmark.py`, and `training/run_ablation_study.py`. | 🟢 **PASS** | Development simulated engine operates via general regex feature parsing on patient text, not lookup against case IDs or ground truth dictionaries. |
| **6** | **Near-duplicate cases** | Jaccard and Levenshtein token similarity analysis across hidden and training datasets. | 🟢 **PASS** | Hard hidden cases utilize atypical clinical presentations (e.g. painless AMI in elderly diabetics, acute limb ischemia, thyrotoxic crisis) distinct from training templates. |
| **7** | **Excessive template overlap** | Syntactic structure and report formatting audit. | 🟢 **PASS** | Hidden laboratory reports introduce novel panels (`hs-CRP`, `D-Dimer FEU`, `Ferritin`, `eGFR CKD-EPI`) with distinct layout and unit representations. |
| **8** | **Paraphrase contamination** | Evaluated vocabulary distributions between patient prompts. | 🟢 **PASS** | Prompt structures were re-engineered with diverse outpatient wording, colloquialisms, and missing context flags. |
| **9** | **Abstention labels not leaking into input** | Inspected sensor corruption and adversarial cases (`NX-HARD-ABS-*`). | 🟢 **PASS** | Input contains only raw contradictory values (e.g. `SpO2: 195%`, `HR: -14 bpm`); the `NOT_ASSESSABLE` tag is generated exclusively by reasoning/safety logic. |
| **10** | **Evaluation code cannot directly access ground truth except through scoring** | Code review of `run_benchmark()` in `ai/evaluation/benchmark.py`. | 🟢 **PASS** | Inference engine receives only `case.input`. Scoring functions (`calculate_lab_tuple_f1`, `evaluate_urgent_recall`) are invoked only after output generation is completed. |

---

## 3. Summary Audit Conclusion

- **Audit Result**: **10 / 10 PASS**
- **Contamination Finding**: No data leakage, label leakage, or ground truth access exists in the evaluation harness.
- **Independence Guarantee**: Measurements on Gold, Hard Hidden, Dedicated RAG, and RAG Holdout benchmarks represent genuine independent task performance.
