import os
import json
import logging
from typing import List, Dict, Any, Tuple, Optional
from pydantic import ValidationError

from ai.schemas.health_analysis import NirogXDatasetExample

logger = logging.getLogger(__name__)

class DatasetValidationError(Exception):
    """Custom exception raised when dataset validation encounters fatal errors."""
    pass

class DatasetValidator:
    def __init__(self, strict_mode: bool = True):
        self.strict_mode = strict_mode

    def validate_example(self, data: Dict[str, Any]) -> Tuple[bool, Optional[NirogXDatasetExample], List[str]]:
        """
        Validates a single dataset record against the canonical NirogX Pydantic schema.
        Fails loudly on malformed fields or invalid enums.
        """
        errors = []
        try:
            example = NirogXDatasetExample.model_validate(data)
            
            # Additional semantic checks
            if not example.id or not example.id.strip():
                errors.append("Example ID cannot be empty.")
            
            if not example.expected_output.summary:
                errors.append("Expected output summary cannot be empty.")
                
            if example.provenance.validation_status not in ["validated", "pending", "rejected"]:
                errors.append(f"Invalid validation_status: {example.provenance.validation_status}")
                
            return (len(errors) == 0, example if len(errors) == 0 else None, errors)
        except ValidationError as ve:
            for err in ve.errors():
                loc = ".".join(str(l) for l in err.get("loc", []))
                msg = err.get("msg", "Validation error")
                errors.append(f"Field '{loc}': {msg}")
            return (False, None, errors)
        except Exception as e:
            errors.append(f"Unexpected error: {str(e)}")
            return (False, None, errors)

    def validate_dataset_file(self, file_path: str) -> Dict[str, Any]:
        """
        Validates an entire JSON dataset file.
        Checks for unique IDs, duplicate detection, and schema compliance.
        """
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"Dataset file not found: {file_path}")

        with open(file_path, "r", encoding="utf-8") as f:
            try:
                raw_data = json.load(f)
            except json.JSONDecodeError as jde:
                raise DatasetValidationError(f"Invalid JSON in {file_path}: {jde}")

        if not isinstance(raw_data, list):
            raise DatasetValidationError(f"Root of dataset {file_path} must be a list of examples.")

        seen_ids = set()
        seen_inputs = set()
        valid_examples: List[NirogXDatasetExample] = []
        record_errors: Dict[str, List[str]] = {}

        for idx, item in enumerate(raw_data):
            rec_id = item.get("id", f"INDEX_{idx}")
            if rec_id in seen_ids:
                err = f"Duplicate example ID detected: {rec_id}"
                record_errors.setdefault(rec_id, []).append(err)
            seen_ids.add(rec_id)

            # Check near-duplicate input hash
            input_summary = json.dumps(item.get("input", {}), sort_keys=True)
            if input_summary in seen_inputs:
                record_errors.setdefault(rec_id, []).append("Duplicate input context detected.")
            seen_inputs.add(input_summary)

            is_valid, example, errors = self.validate_example(item)
            if is_valid and example:
                valid_examples.append(example)
            else:
                record_errors.setdefault(rec_id, []).extend(errors)

        is_passed = len(record_errors) == 0
        report = {
            "file_path": file_path,
            "total_records": len(raw_data),
            "valid_records": len(valid_examples),
            "error_count": len(record_errors),
            "is_passed": is_passed,
            "errors": record_errors
        }

        if not is_passed and self.strict_mode:
            raise DatasetValidationError(
                f"Dataset {file_path} failed validation with {len(record_errors)} faulty records:\n"
                f"{json.dumps(record_errors, indent=2)}"
            )

        return report

    def verify_no_contamination(self, gold_file_path: str, candidate_file_path: str) -> bool:
        """
        Verifies that no gold evaluation cases leak into the training or candidate dataset.
        """
        if not os.path.exists(gold_file_path) or not os.path.exists(candidate_file_path):
            raise FileNotFoundError("Both gold and candidate file paths must exist.")

        with open(gold_file_path, "r", encoding="utf-8") as f:
            gold_data = json.load(f)
        with open(candidate_file_path, "r", encoding="utf-8") as f:
            cand_data = json.load(f)

        gold_ids = {g.get("id") for g in gold_data if "id" in g}
        gold_inputs = {json.dumps(g.get("input", {}), sort_keys=True) for g in gold_data}

        leaked_ids = []
        leaked_inputs = []

        for c in cand_data:
            c_id = c.get("id")
            if c_id in gold_ids:
                leaked_ids.append(c_id)
            c_in = json.dumps(c.get("input", {}), sort_keys=True)
            if c_in in gold_inputs:
                leaked_inputs.append(c_id)

        if leaked_ids or leaked_inputs:
            raise DatasetValidationError(
                f"Contamination Detected! Leaked IDs: {leaked_ids}, Leaked Inputs: {leaked_inputs}"
            )

        return True
