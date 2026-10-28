# 05. NirogX-MedGemma-4B Model Card & Technical Report

## 1. Model Overview & Specifications

- **Model Name**: NirogX-MedGemma-4B (Release Candidate v1.0 / Real Colab GPU Edition)
- **Base Foundation Model**: Google MedGemma 1.5 4B-IT (`google/medgemma-1.5-4b-it`)
- **Model Architecture**: Multimodal Vision-Language Transformer
- **Tuning Methodology**: Parameter-Efficient Fine-Tuning (PEFT / QLoRA 4-bit NF4)
- **Adapter Parameters**: $r=16$, $\alpha=32$, Dropout: $0.05$, Target Modules: `[q_proj, k_proj, v_proj, o_proj, gate_proj, up_proj, down_proj]`
- **Knowledge Base**: `medical-kb-v1.0` (SHA-256: `59cfea48ff279cfc79d73e3f3781dd152f942cb2badaf878b0bdc3690dd5f2eb`)
- **Primary Framework**: PyTorch, Transformers, PEFT, TRL, FastAPI, Pydantic V2
- **Safety Taxonomy**: Dual Deterministic Safety Gates (Gate 1 Pre-Inference Triage + Gate 2 Post-Inference Sanitizer)

---

## 2. Multi-Tier Execution & Validation Tiers

To maintain strict scientific transparency, evaluation results are segmented into four distinct tiers:

```
                                  NIROGX VALIDATION TIERS
                                             │
      ┌───────────────────────────────┬──────┴────────────────────────┬───────────────────────────────┐
      ▼                               ▼                               ▼                               ▼
1. SIMULATED / CONTROLLED       2. REAL MEDGEMMA BASELINE       3. REAL FINE-TUNED MEDGEMMA     4. REAL RAG EVALUATION
   - Release Candidate checks      - Official MedGemma 1.5 4B      - QLoRA LoRA Adapter on GPU     - 4-Quadrant Controlled Ablation
   - Structural schema integrity   - Zero-shot clinical metrics    - Specialized reasoning         - Model vs RAG vs Gate metrics
```

### Tier 1: SIMULATED / DETERMINISTIC VALIDATION (v1.0-RC Benchmark)
- Validated deterministic software pipelines, schema serialization, and baseline safety mechanisms prior to GPU deployment.
- **Urgent Safety Interception**: 84.62% deterministic capture by Gate 1 before model execution.
- **Definitive Claim Defusal**: 100% of prescriptive assertions defused by Gate 2.

### Tier 2: REAL MEDGEMMA BASELINE (google/medgemma-1.5-4b-it on GPU)
- Official Hugging Face foundation model running in 4-bit NF4 on NVIDIA T4/V100/A100.
- Measured direct inference latency, raw token generation speed, and baseline clinical reasoning without domain adapters.
- Runtime provenance tag: `real_medgemma_colab`.

### Tier 3: REAL FINE-TUNED MEDGEMMA (NirogX-MedGemma QLoRA)
- Parameter-efficient LoRA adapter trained on canonical NirogX edge cases (excluding Gold/Hidden/RAG benchmarks).
- Delivers calibrated uncertainty, multi-parameter lab extraction, and acute clinical triage.
- Runtime provenance tag: `real_medgemma_adapter_gpu`.

### Tier 4: REAL RAG EVALUATION (Guideline Grounding Ablation)
- Controlled ablation evaluating Base Model vs Base+RAG vs Fine-Tuned vs Fine-Tuned+RAG.
- Demonstrates knowledge boundary adherence and hallucination reduction on unindexed assays.

---

## 3. Dataset Integrity & Checksums

| Dataset / Component | File Path | SHA-256 Checksum | Permitted Split Use |
| :--- | :--- | :--- | :--- |
| **Gold Benchmark (100 Cases)** | `datasets/gold/gold_evaluation_cases.json` | `bb911e180269a51ee773ecd84f1fa83c81c8458198814321f959ae61ac4b855a` | Benchmark Evaluation ONLY |
| **Hard Hidden Benchmark (100 Cases)** | `datasets/hidden_eval/hidden_evaluation_cases.json` | `a023fa861c2f9c1ea2c9c1949e567be968133454ed14e97aae85ef9682ed0aa3` | Stress-Testing Evaluation ONLY |
| **Dedicated RAG Benchmark (100 Cases)** | `datasets/rag_benchmark/rag_evaluation_cases.json` | `9a45484644983e3198ffbc659186115865ea2816b805886226a45ed1aea640e3` | Guideline Grounding Evaluation ONLY |
| **Medical Knowledge Base v1.0** | `myapp/nirogx_api/ai/rag/knowledge_base.json` | `59cfea48ff279cfc79d73e3f3781dd152f942cb2badaf878b0bdc3690dd5f2eb` | RAG Retrieval Index |

---

## 4. Latency Profile & Execution Provenance

```json
{
  "execution_modes": {
    "real_gpu_colab": {
      "hardware": "NVIDIA Tesla T4 (Colab)",
      "vram_allocated_gb": 3.25,
      "quantization": "4-bit NF4",
      "model_inference_ms": 280.0,
      "total_api_latency_ms": 315.0,
      "runtime_provenance": "real_medgemma_colab"
    },
    "local_simulated_fallback": {
      "hardware": "Local CPU",
      "model_inference_ms": 0.45,
      "total_api_latency_ms": 1.20,
      "runtime_provenance": "simulated_local_engine",
      "usage_policy": "Local unit tests only; strictly prohibited during scientific evaluation"
    }
  }
}
```

---

## 5. Governance & Clinical Disclaimer

- **System Classification**: Research-grade clinical decision-support prototype.
- **Autonomous Prescription Prohibited**: The system strictly refuses drug prescription requests and defuses definitive diagnostic assertions.
- **Not a Diagnostic Device**: Output is intended for decision-support and clinician review only.
