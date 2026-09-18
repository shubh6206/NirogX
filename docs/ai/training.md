# NirogX-MedGemma-4B QLoRA Fine-Tuning Pipeline

## 1. Fine-Tuning Strategy (QLoRA)

The fine-tuning pipeline adapts MedGemma 1.5 4B using 4-bit NormalFloat (NF4) quantization and low-rank parameter-efficient adapters.

```yaml
model:
  name: "google/medgemma-1.5-4b-it"

quantization:
  enabled: true
  quant_type: "nf4"
  use_double_quant: true
  compute_dtype: "bfloat16"

lora:
  r: 16
  lora_alpha: 32
  lora_dropout: 0.05
  bias: "none"
  task_type: "CAUSAL_LM"
  target_modules:
    - "q_proj"
    - "k_proj"
    - "v_proj"
    - "o_proj"
    - "gate_proj"
    - "up_proj"
    - "down_proj"
```

## 2. Running Training

To launch fine-tuning:
```bash
python training/train_qlora.py --config training/configs/medgemma_qlora_default.yaml
```

To run dry-run / simulated pipeline check:
```bash
python training/train_qlora.py --dry-run
```

## 3. Checkpointing & Metadata
Trained adapter checkpoints and metadata are stored in `models/nirogx-medgemma-4b-v0.1/`:
- `adapter_config.json`: LoRA configuration and target projection layers.
- `training_metrics.json`: Dataset version, sample counts, loss curves, and hardware consumption metrics.
