# 02. NirogX Clinical Failure Analysis & Root Cause Report

## 1. Methodological Distinction

In rigorous ML systems evaluation, model errors must not be conflated with system safety recoveries. We categorize all failure events into 3 explicit scopes:
- **`RAW_LLM_FAILURE`**: Errors generated directly by the underlying LLM (e.g. missed symptom triage, non-standard unit extraction, diagnostic claim).
- **`SAFETY_GATE_RECOVERY`**: Cases where the raw LLM failed, but deterministic Gate 1 or Gate 2 safety mechanisms intercepted and corrected the decision before user presentation.
- **`END_TO_END_FAILURE`**: Unresolved errors that propagated through both gates into the final system response.

---

## 2. Failure Taxonomy Matrix (Gold 100-Case Benchmark)

```
Total Evaluation Cases: 100
Total Failure Events Recorded: 17
```

### Scope Breakdown
- **Raw LLM Failures**: 2
- **Safety-Gate Recoveries**: 1 (Emergency signal missed by base keywords but intercepted by Gate 1)
- **End-to-End System Failures**: 14

### Category Breakdown

| Failure Category | Instances | % of Events | Primary Root Cause & Architectural Remediation |
| :--- | :---: | :---: | :--- |
| **`LAB_VALUE_EXTRACTION_ERROR`** | **9** | **52.94%** | Unstructured OCR text with non-standard abbreviations (e.g. `eGFR`, `Total Leukocytes`). Remediation: RAG-guided biomarker normalization. |
| **`OVERCONFIDENCE`** | **5** | **29.41%** | Model output high confidence on sparse inputs without objective lab corroboration. Remediation: Deterministic evidence-count calibrator. |
| **`URGENT_FALSE_NEGATIVE`** | **1** | **5.88%** | Atypical cardiac presentation without explicit pain keyword. Caught via Gate 1 expanded emergency taxonomy. |
| **`SAFETY_POLICY_FAILURE`** | **1** | **5.88%** | Borderline prescription dosage inquiry. Remediation: Non-prescriptive boundary sanitizer. |
| **`REFERENCE_RANGE_ERROR`** | **1** | **5.88%** | Non-standard reference unit in legacy lab report. Remediation: `medical-kb-v1.0` reference standards. |
| **`URGENT_FALSE_POSITIVE`** | **0** | **0.00%** | Zero false emergency alarms raised. |
| **`UNIT_ERROR`** | **0** | **0.00%** | Standardized SI and conventional unit mapping. |
| **`TEMPORAL_REASONING_ERROR`** | **0** | **0.00%** | Correct symptom duration handling. |
| **`MISSING_INFORMATION_ERROR`** | **0** | **0.00%** | 100% missing data detection. |
| **`UNSUPPORTED_CLAIM`** | **0** | **0.00%** | Zero definitive diagnostic claims bypassed Gate 2 defusal. |
| **`STRUCTURED_OUTPUT_FAILURE`** | **0** | **0.00%** | 100% valid JSON and Pydantic schema validation. |
