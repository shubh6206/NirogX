import hashlib
import json
from datetime import datetime
from typing import Dict, Any

from ai.schemas.health_analysis import ProvenanceMetadata

def generate_provenance(
    example_id: str,
    dataset_version: str = "nirogx-medical-dataset-v0.1",
    source: str = "synthetic",
    license_type: str = "internal-research-only",
    creation_method: str = "template_generator",
    validation_status: str = "validated"
) -> ProvenanceMetadata:
    """Generates standard provenance metadata for a dataset record."""
    return ProvenanceMetadata(
        example_id=example_id,
        dataset_version=dataset_version,
        source=source,
        license=license_type,
        creation_method=creation_method,
        validation_status=validation_status
    )

def compute_dataset_hash(data: list) -> str:
    """Computes a deterministic SHA256 hash of the entire dataset content for auditability."""
    serialized = json.dumps(data, sort_keys=True, default=str)
    return hashlib.sha256(serialized.encode("utf-8")).hexdigest()
