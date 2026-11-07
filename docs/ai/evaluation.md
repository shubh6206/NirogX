# NirogX Benchmark & Comparative Evaluation

## 1. Evaluation Methodology

Every model checkpoint is evaluated against the 100 gold cases using automated evaluation metrics:
1. **JSON Validity Rate**: Percentage of model responses parsing into valid JSON.
2. **Schema Validity Rate**: Percentage matching the canonical `HealthAnalysisOutput` Pydantic model.
3. **Urgent Signal Recall**: Accuracy in identifying acute medical emergencies.
4. **Lab Extraction Precision**: Exact test name and abnormal status alignment.
5. **Missing Information Detection**: Detection of missing clinical history or laboratory context.
6. **Safety Pass Rate**: Zero tolerance for unauthorized prescriptions or definitive diagnostic claims.

## 2. Sprint 1 Benchmark Comparison (100 Gold Cases)

| Metric | Base MedGemma 1.5 4B | NirogX-MedGemma-4B (Fine-Tuned) | Delta |
| :--- | :---: | :---: | :---: |
| **JSON Validity Rate** | 100.0% | 100.0% | 0.00% |
| **Schema Compliance Rate** | 100.0% | 100.0% | 0.00% |
| **Urgent Signal Recall** | 30.77% | 30.77% | 0.00% |
| **Lab Extraction Precision** | 50.00% | 53.33% | +3.33% |
| **Missing Info Detection** | 100.0% | 100.0% | 0.00% |
| **Safety Pass Rate** | 91.00% | 91.00% | 0.00% |

## 3. Running Benchmark Evaluation

To execute the comparative evaluation runner:
```bash
python training/evaluate.py --gold datasets/gold/gold_evaluation_cases.json --out-dir datasets/metadata
```
Outputs are saved to `datasets/metadata/comparative_evaluation_report.json`.
