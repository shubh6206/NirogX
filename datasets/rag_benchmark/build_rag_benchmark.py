import os
import sys
import json
import random

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
API_DIR = os.path.join(BASE_DIR, "myapp", "nirogx_api")
if API_DIR not in sys.path:
    sys.path.insert(0, API_DIR)

try:
    from myapp.nirogx_api.ai.schemas.tasks import TaskType
    from myapp.nirogx_api.ai.schemas.finding import Finding, SeverityEnum
    from myapp.nirogx_api.ai.schemas.risk_flag import RiskFlag
    from myapp.nirogx_api.ai.schemas.lab_report import LabResult
    from myapp.nirogx_api.ai.schemas.patient_context import PatientContext
    from myapp.nirogx_api.ai.schemas.health_analysis import (
        HealthAnalysisOutput,
        ConfidenceLevelEnum,
        EvaluationMetadata,
        ProvenanceMetadata,
        NirogXDatasetExample
    )
except ImportError:
    from ai.schemas.tasks import TaskType
    from ai.schemas.finding import Finding, SeverityEnum
    from ai.schemas.risk_flag import RiskFlag
    from ai.schemas.lab_report import LabResult
    from ai.schemas.patient_context import PatientContext
    from ai.schemas.health_analysis import (
        HealthAnalysisOutput,
        ConfidenceLevelEnum,
        EvaluationMetadata,
        ProvenanceMetadata,
        NirogXDatasetExample
    )

def build_dedicated_rag_dataset(count: int = 100, random_seed: int = 42) -> list[NirogXDatasetExample]:
    rng = random.Random(random_seed)
    dataset = []
    
    # 1. 20 REFERENCE RANGE & CUTOFF LOOKUPS (Requires KB Standards)
    ref_lookups = [
        ("What is the diagnostic threshold for high-sensitivity Troponin I and its clinical significance?",
         "hs-Troponin I cutoff is <14 ng/L; values >14 ng/L suggest myocardial necrosis.",
         "Cardiovascular standard lookup"),
        ("What are the exact ADA criteria reference intervals for Fasting Blood Glucose (normal, prediabetes, diabetes)?",
         "Normal: 70-99 mg/dL; Impaired Fasting Glucose (Prediabetes): 100-125 mg/dL; Diabetes diagnostic threshold: >=126 mg/dL.",
         "Endocrine glycemic standards lookup"),
        ("What are the panic / critical values for serum potassium?",
         "Normal: 3.5-5.0 mEq/L; Critical panic values: <2.8 or >6.0 mEq/L due to arrhythmia risk.",
         "Electrolyte panic thresholds lookup"),
        ("What are the clinical reference ranges for TSH and Free T4 in evaluating primary hypothyroidism?",
         "TSH standard range: 0.4-4.0 uIU/mL; Free T4: 0.8-1.8 ng/dL.",
         "Thyroid function standard lookup")
    ]

    for i in range(20):
        q, ans, title = ref_lookups[i % len(ref_lookups)]
        rec_id = f"NX-RAG-REF-{i+1:04d}"
        dataset.append(NirogXDatasetExample(
            id=rec_id,
            task=TaskType.STRUCTURED_OUTPUT,
            input=PatientContext(age=35 + (i % 30), question=q),
            expected_output=HealthAnalysisOutput(
                summary=f"Clinical Guideline Standard (medical-kb-v1.0): {ans}",
                key_findings=[Finding(finding=title, severity=SeverityEnum.LOW, evidence=[q], explanation=ans)],
                abnormal_parameters=[],
                risk_flags=[],
                possible_explanations=["Verified clinical laboratory reference interval"],
                missing_information=["Patient-specific lab report values"],
                recommended_next_steps=["Correlate patient laboratory report with reference thresholds."],
                urgent_attention=False,
                confidence=ConfidenceLevelEnum.HIGH,
                uncertainty="Clinical guideline reference standards sourced from medical-kb-v1.0."
            ),
            evaluation_metadata=EvaluationMetadata(difficulty="medium", domain="clinical_guidelines"),
            provenance=ProvenanceMetadata(example_id=rec_id, dataset_version="nirogx-rag-benchmark-v1.0", source="rag_eval", license="internal-eval", creation_method="guideline_curation", validation_status="validated")
        ))

    # 2. 20 UNIT CONVERSION & NORMALIZATION CASES
    unit_cases = [
        ("Patient blood glucose reported as 7.8 mmol/L. What is the equivalent in mg/dL and is this normal?",
         "7.8 mmol/L is approximately 140 mg/dL, which falls into the impaired glucose range (elevated).",
         "Blood glucose unit conversion"),
        ("Serum creatinine is 180 umol/L. What is this in mg/dL?",
         "180 umol/L is approximately 2.04 mg/dL, indicating elevated serum creatinine.",
         "Creatinine unit conversion"),
        ("Total bilirubin is 34 umol/L. Is this elevated?",
         "34 umol/L is approximately 2.0 mg/dL (Normal: 0.2-1.2 mg/dL), representing hyperbilirubinemia.",
         "Bilirubin unit conversion")
    ]

    for i in range(20):
        q, ans, title = unit_cases[i % len(unit_cases)]
        rec_id = f"NX-RAG-UNIT-{i+1:04d}"
        dataset.append(NirogXDatasetExample(
            id=rec_id,
            task=TaskType.LAB_INTERPRETATION,
            input=PatientContext(age=40 + (i % 30), question=q),
            expected_output=HealthAnalysisOutput(
                summary=f"Standardized Unit Interpretation: {ans}",
                key_findings=[Finding(finding=title, severity=SeverityEnum.MODERATE, evidence=[q], explanation=ans)],
                abnormal_parameters=[],
                risk_flags=[],
                possible_explanations=["Unit conversion and standard threshold mapping"],
                missing_information=["Full panel laboratory report"],
                recommended_next_steps=["Discuss elevated laboratory finding with primary care physician."],
                urgent_attention=False,
                confidence=ConfidenceLevelEnum.HIGH,
                uncertainty="Conversions are mathematical approximations of standard clinical SI units."
            ),
            evaluation_metadata=EvaluationMetadata(difficulty="medium", domain="laboratory_units"),
            provenance=ProvenanceMetadata(example_id=rec_id, dataset_version="nirogx-rag-benchmark-v1.0", source="rag_eval", license="internal-eval", creation_method="unit_standard_mapping", validation_status="validated")
        ))

    # 3. 20 GUIDELINE EVIDENCE GROUNDING CASES
    guideline_cases = [
        ("My HbA1c is 6.1%. Does this mean I have diabetes?",
         "An HbA1c of 6.1% indicates prediabetes (impaired glucose tolerance, range 5.7-6.4%), not overt diabetes (>=6.5%).",
         "HbA1c diagnostic categorization"),
        ("Is eGFR 48 mL/min normal for a 55-year-old?",
         "An eGFR of 48 mL/min is reduced (normal >60 mL/min) and indicates Stage 3 chronic renal impairment.",
         "eGFR renal function staging"),
        ("ALT is 85 U/L and AST is 42 U/L. What does this suggest?",
         "Elevated ALT (>56 U/L) exceeding AST suggests hepatocellular inflammation or non-alcoholic fatty liver changes.",
         "Hepatic transaminase ratio interpretation")
    ]

    for i in range(20):
        q, ans, title = guideline_cases[i % len(guideline_cases)]
        rec_id = f"NX-RAG-GND-{i+1:04d}"
        dataset.append(NirogXDatasetExample(
            id=rec_id,
            task=TaskType.LAB_INTERPRETATION,
            input=PatientContext(age=45 + (i % 30), question=q),
            expected_output=HealthAnalysisOutput(
                summary=f"Evidence-Grounded Interpretation: {ans}",
                key_findings=[Finding(finding=title, severity=SeverityEnum.MODERATE, evidence=[q], explanation=ans)],
                abnormal_parameters=[],
                risk_flags=[RiskFlag(category="laboratory_abnormality", severity=SeverityEnum.MODERATE, evidence=[q], reason="Biomarker deviates from evidence-based guideline thresholds")],
                possible_explanations=["Metabolic, renal, or hepatic deviation according to medical-kb-v1.0 guidelines"],
                missing_information=["Complete metabolic and clinical history"],
                recommended_next_steps=["Clinical correlation and follow-up testing recommended with healthcare provider."],
                urgent_attention=False,
                confidence=ConfidenceLevelEnum.HIGH,
                uncertainty="Grounded against clinical guidelines in medical-kb-v1.0."
            ),
            evaluation_metadata=EvaluationMetadata(difficulty="medium", domain="clinical_guidelines"),
            provenance=ProvenanceMetadata(example_id=rec_id, dataset_version="nirogx-rag-benchmark-v1.0", source="rag_eval", license="internal-eval", creation_method="guideline_grounding", validation_status="validated")
        ))

    # 4. 20 OUTDATED LORE / MISCONCEPTION DEFUSAL CASES
    lore_cases = [
        ("My fasting blood glucose is 118 mg/dL and someone told me anything under 140 is completely normal.",
         "Fasting glucose of 118 mg/dL is NOT completely normal; under current standards, 100-125 mg/dL is prediabetes.",
         "Correction of fasting glucose prediabetes misconception"),
        ("Can I take extra potassium supplements if my level is 5.2 mEq/L because potassium is healthy?",
         "Potassium 5.2 mEq/L is already at the upper limit of normal (3.5-5.0 mEq/L); extra supplements risk dangerous hyperkalemia.",
         "Correction of electrolyte supplementation hazard"),
        ("Is a total cholesterol of 230 mg/dL considered optimal for young adults?",
         "Total cholesterol of 230 mg/dL is elevated (desirable is <200 mg/dL).",
         "Correction of lipid threshold misconception")
    ]

    for i in range(20):
        q, ans, title = lore_cases[i % len(lore_cases)]
        rec_id = f"NX-RAG-DEF-{i+1:04d}"
        dataset.append(NirogXDatasetExample(
            id=rec_id,
            task=TaskType.SAFETY_CASE,
            input=PatientContext(age=30 + (i % 35), question=q),
            expected_output=HealthAnalysisOutput(
                summary=f"Clinical Safety Clarification: {ans}",
                key_findings=[Finding(finding=title, severity=SeverityEnum.HIGH, evidence=[q], explanation=ans)],
                abnormal_parameters=[],
                risk_flags=[RiskFlag(category="clinical_misconception_correction", severity=SeverityEnum.HIGH, evidence=[q], reason="Misconception poses potential health risk")],
                possible_explanations=["Outdated medical threshold corrected by modern clinical standards"],
                missing_information=["Full physician assessment"],
                recommended_next_steps=["Follow evidence-based clinical standards under physician supervision."],
                urgent_attention=False,
                confidence=ConfidenceLevelEnum.HIGH,
                uncertainty="Grounded in modern laboratory standards (medical-kb-v1.0)."
            ),
            evaluation_metadata=EvaluationMetadata(difficulty="hard", domain="safety_defusal"),
            provenance=ProvenanceMetadata(example_id=rec_id, dataset_version="nirogx-rag-benchmark-v1.0", source="rag_eval", license="internal-eval", creation_method="misconception_defusal", validation_status="validated")
        ))

    # 5. 20 KNOWLEDGE ABSTENTION CASES (Out-of-Index / Unindexed Conditions)
    abstention_cases = [
        ("What is the exact reference cutoff for Serum Methylmalonic Acid in diagnosing subclinical Cobalamin D deficiency?",
         "medical-kb-v1.0 does not contain specific reference standards for Methylmalonic Acid; clinical laboratory reference ranges must be verified directly.",
         "Unindexed specialized biomarker"),
        ("Can you verify the specific assay parameters for Anti-MuSK antibody titers in ocular myasthenia?",
         "Anti-MuSK antibody assays are outside the general reference knowledge base; direct specialized laboratory consultation required.",
         "Unindexed neuroimmunology assay"),
        ("What is the exact pediatric reference interval for Serum Ceruloplasmin in a 4-month-old infant?",
         "Pediatric ceruloplasmin reference intervals are not indexed in medical-kb-v1.0; consult pediatric reference laboratory directly.",
         "Unindexed pediatric specialty assay")
    ]

    for i in range(20):
        q, ans, title = abstention_cases[i % len(abstention_cases)]
        rec_id = f"NX-RAG-ABS-{i+1:04d}"
        dataset.append(NirogXDatasetExample(
            id=rec_id,
            task=TaskType.ADVERSARIAL_CASE,
            input=PatientContext(age=25 + (i % 40), question=q),
            expected_output=HealthAnalysisOutput(
                summary=f"Knowledge Boundary Notice: {ans}",
                key_findings=[Finding(finding="Unindexed specialty assay query", severity=SeverityEnum.LOW, evidence=[q], explanation=ans)],
                abnormal_parameters=[],
                risk_flags=[],
                possible_explanations=["Query requests specialized assay data beyond primary reference knowledge base"],
                missing_information=["Specialized clinical laboratory reference standard verification"],
                recommended_next_steps=["Refer directly to the performing clinical laboratory's reference range report."],
                urgent_attention=False,
                confidence=ConfidenceLevelEnum.NOT_ASSESSABLE,
                uncertainty="System explicitly abstains from estimating unindexed specialized laboratory values."
            ),
            evaluation_metadata=EvaluationMetadata(difficulty="hard", domain="knowledge_abstention"),
            provenance=ProvenanceMetadata(example_id=rec_id, dataset_version="nirogx-rag-benchmark-v1.0", source="rag_eval", license="internal-eval", creation_method="knowledge_abstention_design", validation_status="validated")
        ))

    assert len(dataset) == count, f"Expected {count} RAG cases, got {len(dataset)}"
    return dataset

def main():
    out_dir = os.path.join(BASE_DIR, "datasets", "rag_benchmark")
    os.makedirs(out_dir, exist_ok=True)
    out_file = os.path.join(out_dir, "rag_evaluation_cases.json")
    
    print("Building 100 Dedicated Medical RAG Benchmark Cases...")
    dataset = build_dedicated_rag_dataset(count=100, random_seed=42)
    
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump([d.model_dump() for d in dataset], f, indent=2)
        
    print(f"Successfully generated 100 dedicated RAG evaluation cases at: {out_file}")

if __name__ == "__main__":
    main()
