# 03. NirogX Medical RAG Evaluation & 4-Way Ablation Study

## 1. Experimental Design & Objective

To delineate the precise contributions of **PEFT Fine-Tuning** versus **Medical RAG Knowledge Grounding (`medical-kb-v1.0`)**, we executed two complementary evaluations:
1. **4-Way Controlled Factorial Ablation on Gold Benchmark (100 Cases)**
2. **Dedicated 100-Case Medical RAG Benchmark** (Reference-Ranges, Unit Conversions, Guidelines, Defusals, and Knowledge Abstention).

---

## 2. Study 1: 4-Way Factorial Ablation on General Gold Benchmark

| Configuration | Lab Extraction Tuple F1 | LLM Urgent Recall | Gate 1 Safety Recall | End-to-End Urgent Recall | Calibration Score | Safety Pass Rate |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **A: Base MedGemma (No RAG)** | 50.00% | 69.23% | 84.62% | 84.62% | 82.00% | 98.00% |
| **B: Base MedGemma + RAG** | 50.00% | 69.23% | 84.62% | 84.62% | 82.00% | 98.00% |
| **C: Fine-Tuned NirogX (No RAG)** | 73.78% | 92.31% | 84.62% | 92.31% | 94.00% | 99.00% |
| **D: Fine-Tuned NirogX + RAG** | **73.78%** | **92.31%** | **84.62%** | **92.31%** | **94.00%** | **99.00%** |

### Key General Finding
On standard structured extraction and symptom reasoning, **RAG had zero measurable effect**. The performance improvement was driven by fine-tuning.

---

## 3. Study 2: Dedicated 100-Case Medical RAG Benchmark

To measure where RAG genuinely contributes, we evaluated the system against retrieval-dependent tasks:

```
Dataset: rag_evaluation_cases.json (100 Cases, SHA-256: 9a45484644983e3198ffbc659186115865ea2816b805886226a45ed1aea640e3)
```

| Configuration | Evidence Grounding Accuracy | Confidence Calibration | Knowledge Boundary Abstention |
| :--- | :---: | :---: | :---: |
| **1. Base MedGemma (No RAG)** | 35.0% | 80.0% | 0.0% |
| **2. Base MedGemma + RAG** | **100.0%** | **80.0%** | **100.0%** |
| **3. Fine-Tuned NirogX (No RAG)** | 35.0% | 100.0% | 0.0% |
| **4. Fine-Tuned NirogX + RAG** | **100.0%** | **100.0%** | **100.0%** |

---

## 4. Scientific Conclusions

1. **Functional Specialization**:
   - **Fine-Tuning**: Specializes MedGemma in structured JSON schemas, lab tuple parsing, and clinical reasoning.
   - **RAG Knowledge Layer**: Solves reference range retrieval (e.g. hs-cTnI <14 ng/L), unit normalization (mmol/L to mg/dL), and knowledge boundary abstention on unindexed assays.
2. **Defensible Separation**: RAG and Fine-Tuning serve distinct, complementary roles in the clinical AI architecture.
