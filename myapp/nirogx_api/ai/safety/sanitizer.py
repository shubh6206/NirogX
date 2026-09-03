import re
from typing import List, Optional
from ai.schemas.health_analysis import HealthAnalysisOutput

DEFAULT_DISCLAIMER = (
    "AI-generated health information is preliminary and does not replace evaluation by a qualified healthcare professional."
)

DEFAULT_EMERGENCY_ACTION = (
    "Seek immediate emergency medical care or contact your local emergency services (e.g. 112/108/911)."
)

class OutputSanitizer:
    def __init__(self, emergency_action_message: str = DEFAULT_EMERGENCY_ACTION, disclaimer: str = DEFAULT_DISCLAIMER):
        self.emergency_action_message = emergency_action_message
        self.disclaimer = disclaimer

    def sanitize(self, output: HealthAnalysisOutput, force_urgent: bool = False) -> HealthAnalysisOutput:
        """
        Enforces disclaimer injection, definitive diagnosis defusal, emergency escalation,
        and clean deduplication of recommended next steps.
        """
        # 1. Centralized disclaimer injection
        output.disclaimer = self.disclaimer

        # 2. Defuse definitive diagnostic claims in summary
        summary = output.summary
        summary = re.sub(r"(?i)\bi diagnose you with\b", "findings are consistent with possible", summary)
        summary = re.sub(r"(?i)\byou definitely have\b", "results suggest evaluating for", summary)
        output.summary = summary

        # 3. Handle emergency escalation
        if force_urgent:
            output.urgent_attention = True

        # 4. Deduplicate recommended next steps
        deduped_steps = []
        has_emergency_step = False

        if output.urgent_attention:
            deduped_steps.append(self.emergency_action_message)
            has_emergency_step = True

        for step in output.recommended_next_steps:
            step_clean = step.strip()
            if not step_clean:
                continue

            # If it's another emergency string and we already added one, skip it
            is_emergency_variant = any(
                phrase in step_clean.lower() for phrase in [
                    "seek immediate emergency", "call 911", "call 112", "emergency medical care", "local emergency services"
                ]
            )
            if is_emergency_variant and has_emergency_step:
                continue

            # Case-insensitive deduplication
            if not any(step_clean.lower() == existing.lower() for existing in deduped_steps):
                deduped_steps.append(step_clean)

        output.recommended_next_steps = deduped_steps
        return output
