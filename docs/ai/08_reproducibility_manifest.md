# 08. NirogX Reproducibility Manifest (v1.0-RC)

## 1. System & Execution Metadata

```json
{
  "release_version": "NirogX-MedGemma-4B-v1.0-RC",
  "audit_timestamp": "2026-09-02T20:25:00Z",
  "python_version": "3.12.10 (tags/v3.12.10:00bf0c1)",
  "platform": "win32",
  "runtime_provenance": "simulated_local_engine (CPU Development Environment)",
  "gpu_inference_status": "BLOCKED in current Windows CPU environment; production target: NVIDIA T4 / A10G",
  "target_base_model": "google/medgemma-1.5-4b-it",
  "adapter_config_path": "models/nirogx-medgemma-4b-v0.1/adapter_config.json",
  "adapter_parameters": {
    "peft_type": "LORA",
    "r": 16,
    "lora_alpha": 32,
    "lora_dropout": 0.05,
    "target_modules": ["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"]
  }
}
```

---

## 2. Dataset Cryptographic Fingerprints (SHA-256)

| Dataset | Relative Path | SHA-256 Checksum |
| :--- | :--- | :--- |
| **Gold Benchmark (100 Cases)** | `datasets/gold/gold_evaluation_cases.json` | `bb911e180269a51ee773ecd84f1fa83c81c8458198814321f959ae61ac4b855a` |
| **Hard Hidden Benchmark (100 Cases)** | `datasets/hidden_eval/hidden_evaluation_cases.json` | `a023fa861c2f9c1ea2c9c1949e567be968133454ed14e97aae85ef9682ed0aa3` |
| **Dedicated RAG Benchmark (100 Cases)** | `datasets/rag_benchmark/rag_evaluation_cases.json` | `9a45484644983e3198ffbc659186115865ea2816b805886226a45ed1aea640e3` |
| **RAG Holdout Challenge (100 Cases)** | `datasets/rag_benchmark/rag_holdout_cases.json` | `7efab96b65461c5dda12ec1f92ed7a22be640ff5ca7433669ab013513dd8c389` |
| **Knowledge Base (medical-kb-v1.0)** | `myapp/nirogx_api/ai/rag/knowledge_base.json` | `59cfea48ff279cfc79d73e3f3781dd152f942cb2badaf878b0bdc3690dd5f2eb` |

---

## 3. Reproduction Commands

### Automated Test Suite (36/36 passing)
```powershell
& .\myapp\nirogx_api\venv_win\Scripts\python.exe -m pytest
```

### Complete Benchmark Reproduction & Manifest Generation
```powershell
& .\myapp\nirogx_api\venv_win\Scripts\python.exe training/reproduce_rc_benchmark.py
```

### Codebase Compilation Check (0 errors)
```powershell
& .\myapp\nirogx_api\venv_win\Scripts\python.exe -m compileall myapp\nirogx_api\ai datasets training
```
