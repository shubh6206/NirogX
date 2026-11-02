# NirogX Reproducibility Guide (v1.0-RC)

## 1. Clean-Environment Execution

All benchmarks, confidence intervals, and 4-way ablation matrices can be reproduced from a clean environment using the automated master script:

```powershell
& .\myapp\nirogx_api\venv_win\Scripts\python.exe training/reproduce_rc_benchmark.py
```

---

## 2. Dataset Cryptographic Verification (SHA-256)

```powershell
# Verify dataset integrity
Get-FileHash datasets/gold/gold_evaluation_cases.json
Get-FileHash datasets/hidden_eval/hidden_evaluation_cases.json
Get-FileHash datasets/rag_benchmark/rag_evaluation_cases.json
Get-FileHash datasets/rag_benchmark/rag_holdout_cases.json
Get-FileHash myapp/nirogx_api/ai/rag/knowledge_base.json
```

Expected Hashes:
- `gold_evaluation_cases.json`: `bb911e180269a51ee773ecd84f1fa83c81c8458198814321f959ae61ac4b855a`
- `hidden_evaluation_cases.json`: `a023fa861c2f9c1ea2c9c1949e567be968133454ed14e97aae85ef9682ed0aa3`
- `rag_evaluation_cases.json`: `9a45484644983e3198ffbc659186115865ea2816b805886226a45ed1aea640e3`
- `rag_holdout_cases.json`: `7efab96b65461c5dda12ec1f92ed7a22be640ff5ca7433669ab013513dd8c389`
- `knowledge_base.json (medical-kb-v1.0)`: `59cfea48ff279cfc79d73e3f3781dd152f942cb2badaf878b0bdc3690dd5f2eb`

---

## 3. Automated Test Suite Execution

```powershell
& .\myapp\nirogx_api\venv_win\Scripts\python.exe -m pytest myapp/nirogx_api/tests/
```
Output: `36 passed in ~20s`
