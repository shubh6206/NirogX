import os
import logging
from typing import Dict, Any, Optional, Tuple

logger = logging.getLogger(__name__)

class MultimodalDocumentProcessor:
    """
    Multimodal Document & Vision Processor for NirogX Medical Intelligence.
    Handles image document verification, text extraction normalization, and corruption detection.
    """
    def __init__(self):
        self.supported_extensions = [".png", ".jpg", ".jpeg", ".webp"]

    def validate_image_attachment(self, image_path: Optional[str]) -> Tuple[bool, str]:
        if not image_path:
            return False, "No image reference provided"
        
        if not os.path.exists(image_path):
            return False, f"Image path does not exist: {image_path}"
            
        ext = os.path.splitext(image_path)[1].lower()
        if ext not in self.supported_extensions:
            return False, f"Unsupported image format: {ext}. Must be PNG, JPEG, or WEBP."

        return True, "Valid medical image document"

    def normalize_ocr_text(self, raw_ocr: str) -> Tuple[str, bool]:
        """
        Normalizes common OCR artifact errors while detecting when corruption is too severe for assessment.
        """
        cleaned = raw_ocr.strip()
        
        # Detect severe unrecoverable corruption
        if "H##g?" in cleaned or "???" in cleaned or "unreadable" in cleaned.lower():
            return cleaned, False # False indicates unassessable / abstention needed

        # Common OCR fixes
        cleaned = cleaned.replace("Hb -", "Hb:").replace("HGB.....", "Hb: ").replace("Haemoglobin", "Hemoglobin")
        return cleaned, True
