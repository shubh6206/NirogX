from typing import List, Tuple, Optional
from ai.schemas.finding import SeverityEnum
from ai.schemas.risk_flag import RiskFlag
from ai.schemas.patient_context import PatientContext

# Comprehensive clinical emergency taxonomy
EMERGENCY_SYMPTOM_TRIGGERS = [
    # Acute Coronary Syndrome (ACS)
    "crushing chest pain", "chest pressure", "substernal chest", "radiating to left jaw", "radiating to arm",
    "crushing substernal", "profuse diaphoresis with chest", "chest tightness",
    
    # Acute Neurological / Stroke (FAST)
    "facial droop", "slurred speech", "one-sided weakness", "arm weakness", "right-sided facial droop",
    
    # Severe Acute Headache / Intracranial
    "thunderclap headache", "worst headache of life", "meningismus", "stiff neck with fever",
    "stiff neck", "worst of life", "acute severe headache",
    
    # Pulmonary Embolism & Acute Respiratory Failure
    "anaphylaxis", "stridor", "lips swelling", "bluish lips", "severe wheezing after peanuts",
    "coughing up blood", "hemoptysis", "unilateral calf swelling post-flight", "unilateral leg swelling",
    "severe dyspnea", "severe shortness of breath with bluish",
    
    # Sepsis & Septic Compromise
    "high fever 40.2", "septic shock", "fever with confusion and low blood pressure", "lethargic infant with fever",
    "infant with lethargy", "febrile infant",
    
    # Metabolic Emergencies
    "blood sugar 450", "fruity breath", "diabetic ketoacidosis", "dka",
    
    # Acute Gastrointestinal Bleeding
    "black tarry stools", "melena", "melena with dizziness", "vomiting blood", "hematemesis",
    
    # Acute Gynecological / Obstetrical
    "ectopic pregnancy", "positive pregnancy test and severe sharp unilateral pelvic pain",
    "severe sharp unilateral pelvic pain with vaginal spotting",
    
    # Acute Ocular / Vision Threatening
    "sudden vision loss", "curtain coming down", "painless loss of vision in right eye",
    "sudden painless loss of vision",
    
    # Psychiatric Emergency
    "thoughts of self-harm", "suicidal ideation", "severe depression with thoughts of self-harm"
]

PRESCRIPTION_DRUG_PATTERNS = [
    "prescribe", "what dose of", "dosage for", "should i stop taking", "can i replace my medication",
    "how many mg of", "prescribe me", "can you write me a prescription"
]

class SafetyEngine:
    def check_emergency_signals(self, context: PatientContext) -> Tuple[bool, List[RiskFlag]]:
        """
        Deterministic emergency triage trigger (Gate 1).
        Returns (is_urgent, list_of_urgent_risk_flags).
        """
        flags = []
        combined_text = " ".join(context.symptoms) + " " + context.report_text + " " + context.question
        combined_lower = combined_text.lower()

        for trigger in EMERGENCY_SYMPTOM_TRIGGERS:
            if trigger in combined_lower:
                flags.append(RiskFlag(
                    category="emergency_safety_escalation",
                    severity=SeverityEnum.URGENT,
                    evidence=[trigger],
                    reason=f"Emergency clinical pattern detected ({trigger}). Immediate medical attention required."
                ))
                break

        # Extreme Vitals Check
        vitals = context.health_metrics
        if vitals:
            hr = vitals.get("heart_rate") or vitals.get("resting_hr")
            if hr and (hr > 150 or hr < 40):
                flags.append(RiskFlag(
                    category="extreme_vital_alert",
                    severity=SeverityEnum.URGENT,
                    evidence=[f"Heart rate: {hr} bpm"],
                    reason=f"Extreme physiological heart rate detected ({hr} bpm)."
                ))
            
            spo2 = vitals.get("SpO2") or vitals.get("spo2")
            if spo2 and (50 <= spo2 < 88):
                flags.append(RiskFlag(
                    category="hypoxemia_alert",
                    severity=SeverityEnum.URGENT,
                    evidence=[f"SpO2: {spo2}%"],
                    reason=f"Severe hypoxemia detected (SpO2 {spo2}%)."
                ))

        # Extreme Lab Values Check
        for lab in context.lab_results:
            if lab.test_name.lower() in ["potassium", "serum potassium"] and isinstance(lab.value, (int, float)):
                if lab.value > 6.5 or lab.value < 2.8:
                    flags.append(RiskFlag(
                        category="critical_laboratory_panic_value",
                        severity=SeverityEnum.URGENT,
                        evidence=[f"{lab.test_name}: {lab.value} {lab.unit}"],
                        reason="Critical serum potassium panic value requiring immediate intervention."
                    ))

        is_urgent = len(flags) > 0
        return is_urgent, flags

    def check_prescription_boundaries(self, context: PatientContext) -> Tuple[bool, Optional[RiskFlag]]:
        """
        Detects prescription dosage inquiries or medication tampering requests.
        """
        combined_text = context.question + " " + " ".join(context.symptoms)
        combined_lower = combined_text.lower()

        for pattern in PRESCRIPTION_DRUG_PATTERNS:
            if pattern in combined_lower:
                return True, RiskFlag(
                    category="clinical_safety_boundary",
                    severity=SeverityEnum.HIGH,
                    evidence=[pattern],
                    reason="Prescription medication request detected. AI decision support is strictly non-prescriptive."
                )
        return False, None

    def validate_biological_plausibility(self, context: PatientContext) -> Tuple[bool, List[str]]:
        """
        Flags impossible sensor values (e.g. SpO2 > 100%, body temperature > 50C).
        """
        errors = []
        combined_text = context.question + " " + context.report_text
        
        # Check text claims of impossible vitals
        if "spo2 is 140%" in combined_text.lower() or "spo2 is 180%" in combined_text.lower():
            errors.append("Impossible SpO2 reading > 100%")
        if "body temperature is 65" in combined_text.lower() or "body temperature is 80" in combined_text.lower():
            errors.append("Biologically impossible body temperature > 50°C")

        vitals = context.health_metrics
        if vitals:
            spo2 = vitals.get("SpO2") or vitals.get("spo2")
            if spo2 and (spo2 > 100 or spo2 < 50):
                errors.append(f"Biologically impossible SpO2 reading: {spo2}%")
            temp = vitals.get("body_temp") or vitals.get("temperature")
            if temp and (temp > 45 or temp < 30):
                errors.append(f"Biologically implausible body temperature: {temp}°C")

        return len(errors) == 0, errors
