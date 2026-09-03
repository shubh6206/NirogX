from enum import Enum

class RuntimeProvenance(str, Enum):
    """
    Strongly typed runtime provenance identifying the execution environment and model origin.
    """
    REAL_MEDGEMMA_COLAB = "real_medgemma_colab"
    REAL_MEDGEMMA_LOCAL_GPU = "real_medgemma_local_gpu"
    REAL_MEDGEMMA_ADAPTER_GPU = "real_medgemma_adapter_gpu"
    SIMULATED_LOCAL_ENGINE = "simulated_local_engine"

    def is_real_model(self) -> bool:
        """Returns True if the provenance indicates genuine GPU model inference."""
        return self in (
            RuntimeProvenance.REAL_MEDGEMMA_COLAB,
            RuntimeProvenance.REAL_MEDGEMMA_LOCAL_GPU,
            RuntimeProvenance.REAL_MEDGEMMA_ADAPTER_GPU,
        )
