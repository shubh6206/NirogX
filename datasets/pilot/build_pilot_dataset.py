import os
import sys

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
API_DIR = os.path.join(BASE_DIR, "myapp", "nirogx_api")
sys.path.insert(0, API_DIR)

from ai.dataset.generator import generate_pilot_dataset
from ai.dataset.splitter import split_dataset, save_and_verify_splits

def main():
    gold_path = os.path.join(BASE_DIR, "datasets", "gold", "gold_evaluation_cases.json")
    pilot_dir = os.path.join(BASE_DIR, "datasets", "pilot")
    
    print("Generating 600 stratified pilot examples...")
    dataset = generate_pilot_dataset(count=600, random_seed=42)
    
    print("Splitting into 80% Train / 10% Validation / 10% Test...")
    train_set, val_set, test_set = split_dataset(dataset, 0.8, 0.1, 0.1, random_seed=42)
    print(f"Split sizes: Train={len(train_set)}, Val={len(val_set)}, Test={len(test_set)}")
    
    print("Saving and validating splits...")
    save_and_verify_splits(train_set, val_set, test_set, gold_path, pilot_dir)

if __name__ == "__main__":
    main()
