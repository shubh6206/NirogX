import os
import json
import random
from typing import List, Dict, Any, Tuple

from ai.schemas.health_analysis import NirogXDatasetExample
from ai.dataset.validator import DatasetValidator

def split_dataset(
    examples: List[NirogXDatasetExample],
    train_ratio: float = 0.80,
    val_ratio: float = 0.10,
    test_ratio: float = 0.10,
    random_seed: int = 42
) -> Tuple[List[NirogXDatasetExample], List[NirogXDatasetExample], List[NirogXDatasetExample]]:
    """
    Splits a dataset into deterministic train, validation, and test subsets.
    """
    assert abs(train_ratio + val_ratio + test_ratio - 1.0) < 1e-5, "Ratios must sum to 1.0"
    
    # Stratify by task type
    by_task: Dict[str, List[NirogXDatasetExample]] = {}
    for ex in examples:
        by_task.setdefault(ex.task.value, []).append(ex)

    train_set, val_set, test_set = [], [], []
    rng = random.Random(random_seed)

    for task_name, task_examples in by_task.items():
        shuffled = list(task_examples)
        rng.shuffle(shuffled)
        n = len(shuffled)
        n_train = int(n * train_ratio)
        n_val = int(n * val_ratio)
        
        train_set.extend(shuffled[:n_train])
        val_set.extend(shuffled[n_train:n_train + n_val])
        test_set.extend(shuffled[n_train + n_val:])

    return train_set, val_set, test_set

def save_and_verify_splits(
    train_set: List[NirogXDatasetExample],
    val_set: List[NirogXDatasetExample],
    test_set: List[NirogXDatasetExample],
    gold_path: str,
    output_dir: str
):
    """Saves splits and verifies zero leakage with gold benchmark."""
    os.makedirs(output_dir, exist_ok=True)
    validator = DatasetValidator(strict_mode=True)

    splits = {
        "train": (train_set, os.path.join(output_dir, "train.json")),
        "validation": (val_set, os.path.join(output_dir, "val.json")),
        "test": (test_set, os.path.join(output_dir, "test.json")),
    }

    full_pilot = train_set + val_set + test_set
    full_pilot_path = os.path.join(output_dir, "pilot_dataset.json")
    with open(full_pilot_path, "w", encoding="utf-8") as f:
        json.dump([e.model_dump(mode="json") for e in full_pilot], f, indent=2)

    for split_name, (data, path) in splits.items():
        serialized = [e.model_dump(mode="json") for e in data]
        with open(path, "w", encoding="utf-8") as f:
            json.dump(serialized, f, indent=2)
        print(f"Saved {len(data)} {split_name} records to {path}")
        
        # Verify schema validity
        validator.validate_dataset_file(path)
        
        # Verify zero contamination with Gold benchmark
        validator.verify_no_contamination(gold_path, path)

    print("All splits validated successfully with ZERO gold contamination verified!")
