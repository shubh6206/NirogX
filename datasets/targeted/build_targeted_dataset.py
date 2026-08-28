import os
import sys

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
API_DIR = os.path.join(BASE_DIR, "myapp", "nirogx_api")
sys.path.insert(0, API_DIR)

from ai.dataset.targeted_generator import generate_targeted_failure_dataset
from ai.dataset.splitter import split_dataset, save_and_verify_splits

def main():
    gold_path = os.path.join(BASE_DIR, "datasets", "gold", "gold_evaluation_cases.json")
    out_dir = os.path.join(BASE_DIR, "datasets", "targeted")
    
    print("Generating 500 targeted failure-mode clinical variants...")
    dataset = generate_targeted_failure_dataset(count=500, random_seed=101)
    
    print("Splitting into 80% Train (400) / 10% Validation (50) / 10% Test (50)...")
    train_set, val_set, test_set = split_dataset(dataset, 0.8, 0.1, 0.1, random_seed=101)
    print(f"Split sizes: Train={len(train_set)}, Val={len(val_set)}, Test={len(test_set)}")
    
    print("Saving and validating targeted splits...")
    save_and_verify_splits(train_set, val_set, test_set, gold_path, out_dir)

if __name__ == "__main__":
    main()
