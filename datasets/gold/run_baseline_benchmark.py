import os
import sys
import json

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
API_DIR = os.path.join(BASE_DIR, "myapp", "nirogx_api")
sys.path.insert(0, API_DIR)

from ai.inference.medgemma import MedGemmaInferenceEngine
from ai.evaluation.benchmark import run_benchmark

def main():
    gold_path = os.path.join(BASE_DIR, "datasets", "gold", "gold_evaluation_cases.json")
    report_out = os.path.join(BASE_DIR, "datasets", "metadata", "baseline_eval_report.json")
    
    engine = MedGemmaInferenceEngine(
        model_name_or_path="google/medgemma-1.5-4b-it",
        use_fallback_if_unavailable=True
    )
    
    report = run_benchmark(
        gold_cases_path=gold_path,
        inference_engine=engine,
        output_report_path=report_out
    )
    
    print("\n================== BASELINE BENCHMARK SUMMARY ==================")
    print(json.dumps(report["summary"], indent=2))
    print("===============================================================\n")

if __name__ == "__main__":
    main()
