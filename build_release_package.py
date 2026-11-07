import os
import shutil
import json

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
RELEASE_DIR = os.path.join(BASE_DIR, "release", "NirogX-MedGemma-4B-v1.0-RC")

# 1. Directories
dirs = [
    os.path.join(RELEASE_DIR, "model", "adapter"),
    os.path.join(RELEASE_DIR, "benchmarks", "gold"),
    os.path.join(RELEASE_DIR, "benchmarks", "hidden"),
    os.path.join(RELEASE_DIR, "benchmarks", "rag"),
    os.path.join(RELEASE_DIR, "benchmarks", "holdout"),
    os.path.join(RELEASE_DIR, "results"),
    os.path.join(RELEASE_DIR, "documentation")
]

for d in dirs:
    os.makedirs(d, exist_ok=True)

# 2. Model Info
model_info = {
    "model_name": "NirogX-MedGemma-4B",
    "version": "1.0-RC",
    "base_model": "google/medgemma-1.5-4b-it",
    "tuning_method": "PEFT / QLoRA 4-bit NF4",
    "adapter_config": {
        "r": 16,
        "lora_alpha": 32,
        "lora_dropout": 0.05,
        "target_modules": ["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"]
    },
    "knowledge_base": "medical-kb-v1.0",
    "safety_gates": ["Gate 1: Pre-Inference Triage", "Gate 2: Post-Inference Sanitizer"]
}

with open(os.path.join(RELEASE_DIR, "model", "MODEL_INFO.json"), "w", encoding="utf-8") as f:
    json.dump(model_info, f, indent=2)

# 3. Copy Model Adapter
src_adapter = os.path.join(BASE_DIR, "models", "nirogx-medgemma-4b-v0.1")
dst_adapter = os.path.join(RELEASE_DIR, "model", "adapter")
if os.path.exists(src_adapter):
    for item in os.listdir(src_adapter):
        s = os.path.join(src_adapter, item)
        d = os.path.join(dst_adapter, item)
        if os.path.isdir(s):
            shutil.copytree(s, d, dirs_exist_ok=True)
        else:
            shutil.copy2(s, d)

# 4. Copy Benchmarks
shutil.copy2(os.path.join(BASE_DIR, "datasets", "gold", "gold_evaluation_cases.json"), os.path.join(RELEASE_DIR, "benchmarks", "gold"))
shutil.copy2(os.path.join(BASE_DIR, "datasets", "hidden_eval", "hidden_evaluation_cases.json"), os.path.join(RELEASE_DIR, "benchmarks", "hidden"))
shutil.copy2(os.path.join(BASE_DIR, "datasets", "rag_benchmark", "rag_evaluation_cases.json"), os.path.join(RELEASE_DIR, "benchmarks", "rag"))
shutil.copy2(os.path.join(BASE_DIR, "datasets", "rag_benchmark", "rag_holdout_cases.json"), os.path.join(RELEASE_DIR, "benchmarks", "holdout"))

# 5. Copy Results
shutil.copy2(os.path.join(BASE_DIR, "evaluation", "general_benchmark.json"), os.path.join(RELEASE_DIR, "results"))
shutil.copy2(os.path.join(BASE_DIR, "evaluation", "hidden_benchmark.json"), os.path.join(RELEASE_DIR, "results"))
shutil.copy2(os.path.join(BASE_DIR, "evaluation", "rag_benchmark.json"), os.path.join(RELEASE_DIR, "results"))
shutil.copy2(os.path.join(BASE_DIR, "evaluation", "rag_holdout_benchmark.json"), os.path.join(RELEASE_DIR, "results"))

# 6. Copy Documentation
shutil.copy2(os.path.join(BASE_DIR, "docs", "model_card.md"), os.path.join(RELEASE_DIR, "documentation"))
shutil.copy2(os.path.join(BASE_DIR, "docs", "technical_report.md"), os.path.join(RELEASE_DIR, "documentation"))
shutil.copy2(os.path.join(BASE_DIR, "docs", "safety.md"), os.path.join(RELEASE_DIR, "documentation"))
shutil.copy2(os.path.join(BASE_DIR, "docs", "reproducibility.md"), os.path.join(RELEASE_DIR, "documentation"))

# 7. Copy SHA256SUMS
shutil.copy2(os.path.join(BASE_DIR, "checksums", "SHA256SUMS"), RELEASE_DIR)

print(f"Successfully constructed release artifact at: {RELEASE_DIR}")
