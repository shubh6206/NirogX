# NirogX AI Dataset Specification & Governance

## 1. Dataset Taxonomy & Splits

NirogX adheres to strict separation between the **Gold Evaluation Benchmark** and **Synthetic Pilot Training Sets**:

### A. Gold Benchmark Dataset (100 Immutable Cases)
*Location: `datasets/gold/gold_evaluation_cases.json`*
* **15 Laboratory Extraction Cases**: CBC, Metabolic, Lipid, Liver, Thyroid, Electrolytes, Arterial Blood Gas, Coagulation.
* **15 Laboratory Interpretation Cases**: Glycemic shifts, subtle anemia, transaminase elevations.
* **15 Symptom Analysis Cases**: Respiratory, GI, cardiovascular, neurological, musculoskeletal.
* **10 Health Summary Cases**: Daily wearable metrics, sleep quality, activity levels.
* **10 Longitudinal Analytics Cases**: Multi-month resting heart rate, blood pressure, glycemic trends.
* **15 Medical Document Cases**: Clinical discharge notes with multimodal image references (`datasets/gold/images/`).
* **15 Safety & Uncertainty Cases**: Acute coronary syndrome, stroke, DKA, pediatric prescription requests, certainty demands.
* **5 Adversarial / Edge Cases**: Impossible biometric readings (SpO2 > 100%, body temp > 50°C), prompt injection.

> **CRITICAL RULE**: The 100 gold cases are immutable and strictly excluded from training pipelines.

### B. Pilot Synthetic Training Dataset (600 Examples)
*Location: `datasets/pilot/`*
* **Train Set (80%, 480 examples)**: `datasets/pilot/train.json`
* **Validation Set (10%, 60 examples)**: `datasets/pilot/val.json`
* **Test Set (10%, 60 examples)**: `datasets/pilot/test.json`

## 2. Provenance & Audit Metadata
Each dataset record contains provenance tracking:
```json
{
  "example_id": "NX-PILOT-EXT-0001",
  "dataset_version": "nirogx-medical-dataset-v0.1",
  "source": "synthetic",
  "license": "internal-research",
  "creation_method": "template_generator",
  "validation_status": "validated"
}
```

## 3. Dataset Validation Engine
The validator (`myapp/nirogx_api/ai/dataset/validator.py`) enforces:
1. Pydantic schema compliance for all fields and enums.
2. Unique ID enforcement.
3. Duplicate input context detection.
4. Gold leakage prevention (`verify_no_contamination`).
