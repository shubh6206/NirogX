import os
import json
import logging
from typing import List, Dict, Any, Optional

from ai.schemas.patient_context import PatientContext

logger = logging.getLogger(__name__)

class MedicalRAGRetriever:
    """
    Versioned Medical Knowledge Base Retriever.
    Retrieves verified reference standards and clinical guidelines for evidence-grounded generation.
    """
    def __init__(self, kb_path: Optional[str] = None):
        if not kb_path:
            kb_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "knowledge_base.json")
        
        self.kb_path = kb_path
        self.kb_version = "medical-kb-v1.0"
        self.guidelines = []
        self._load_knowledge_base()

    def _load_knowledge_base(self):
        try:
            with open(self.kb_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                self.kb_version = data.get("kb_version", "medical-kb-v1.0")
                self.guidelines = data.get("guidelines", [])
        except Exception as e:
            logger.warning(f"Failed to load Medical KB from {self.kb_path}: {e}")
            self.guidelines = []

    def retrieve_guidelines(self, context: PatientContext, top_k: int = 2) -> List[Dict[str, Any]]:
        """
        Retrieves matching guidelines based on symptoms, lab results, and clinical query.
        """
        if not self.guidelines:
            return []

        # Construct query token string
        tokens = []
        tokens.extend([s.lower() for s in context.symptoms])
        tokens.extend([l.test_name.lower() for l in context.lab_results])
        if context.question:
            tokens.append(context.question.lower())
        if context.report_text:
            tokens.append(context.report_text.lower())
            
        full_query = " ".join(tokens)

        scored_guidelines = []
        for g in self.guidelines:
            score = 0
            for kw in g.get("keywords", []):
                if kw in full_query:
                    score += 1
            if score > 0:
                scored_guidelines.append((score, g))

        scored_guidelines.sort(key=lambda x: x[0], reverse=True)
        return [g for _, g in scored_guidelines[:top_k]]

    def format_grounded_context(self, retrieved: List[Dict[str, Any]]) -> str:
        """
        Formats retrieved guidelines into structured text for prompt injection.
        """
        if not retrieved:
            return ""

        parts = [f"--- RETRIEVED CLINICAL GUIDELINES ({self.kb_version}) ---"]
        for g in retrieved:
            parts.append(f"• [{g.get('category').upper()}] {g.get('title')}:")
            parts.append(f"  - Standards: {json.dumps(g.get('reference_standards', {}))}")
            parts.append(f"  - Clinical Guidance: {g.get('clinical_guidance')}")
        parts.append("-----------------------------------------------------")
        return "\n".join(parts)
