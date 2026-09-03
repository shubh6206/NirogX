import os
import json
import time
import logging
import urllib.request
import urllib.error
from typing import Dict, Any, Optional, Tuple

try:
    from myapp.nirogx_api.ai.schemas.patient_context import PatientContext
    from myapp.nirogx_api.ai.schemas.health_analysis import HealthAnalysisOutput, ConfidenceLevelEnum
    from myapp.nirogx_api.ai.schemas.provenance import RuntimeProvenance
    from myapp.nirogx_api.ai.inference.prompts import SYSTEM_PROMPT, format_patient_context_prompt
except ImportError:
    from ai.schemas.patient_context import PatientContext
    from ai.schemas.health_analysis import HealthAnalysisOutput, ConfidenceLevelEnum
    from ai.schemas.provenance import RuntimeProvenance
    from ai.inference.prompts import SYSTEM_PROMPT, format_patient_context_prompt

logger = logging.getLogger(__name__)

class RealModelExecutionError(RuntimeError):
    """Raised when MEDGEMMA_EVALUATION_MODE is enabled but genuine model inference is unavailable."""
    pass

class RemoteModelConnectionError(RuntimeError):
    """Raised when communication with remote MedGemma server fails during evaluation mode."""
    pass

class MedGemmaInferenceEngine:
    """
    Unified Multimodal Inference Engine for MedGemma 1.5 4B and NirogX-MedGemma-4B adapters.
    Supports Local HuggingFace GPU, Remote Colab GPU Server (via ngrok/tunnel), and Fallback Simulator.
    Preserves strict runtime provenance and evaluation mode enforcement.
    """
    def __init__(
        self,
        model_name_or_path: str = "google/medgemma-1.5-4b-it",
        adapter_path: Optional[str] = None,
        remote_api_url: Optional[str] = None,
        load_in_4bit: bool = True,
        device_map: str = "auto",
        use_fallback_if_unavailable: bool = True,
        evaluation_mode: Optional[bool] = None
    ):
        self.model_name_or_path = model_name_or_path
        self.adapter_path = adapter_path
        self.remote_api_url = remote_api_url or os.getenv("MEDGEMMA_REMOTE_URL")
        self.load_in_4bit = load_in_4bit
        self.device_map = device_map
        
        # Check evaluation mode flag
        if evaluation_mode is not None:
            self.evaluation_mode = evaluation_mode
        else:
            self.evaluation_mode = os.getenv("MEDGEMMA_EVALUATION_MODE", "").lower() in ("true", "1", "yes")
            
        # In evaluation mode, simulation and silent fallbacks are strictly prohibited
        if self.evaluation_mode:
            self.use_fallback_if_unavailable = False
        else:
            self.use_fallback_if_unavailable = use_fallback_if_unavailable
        
        self.model = None
        self.tokenizer = None
        self.processor = None
        self.is_loaded = False
        self.is_mock_fallback = False
        self.runtime_type = "uninitialized"
        self.last_remote_status = "NONE"
        
        self._initialize_model()

    def _initialize_model(self):
        """Attempts to load the model via Remote Colab API, PyTorch/Transformers, or switches to fallback."""
        if self.remote_api_url:
            logger.info(f"MedGemma remote API endpoint configured: {self.remote_api_url}")
            self.runtime_type = RuntimeProvenance.REAL_MEDGEMMA_COLAB.value
            self.is_loaded = True
            return

        try:
            import torch
            from transformers import AutoTokenizer, AutoProcessor, AutoModelForCausalLM
            
            logger.info(f"Loading tokenizer & processor for {self.model_name_or_path}...")
            self.tokenizer = AutoTokenizer.from_pretrained(self.model_name_or_path, trust_remote_code=True)
            try:
                self.processor = AutoProcessor.from_pretrained(self.model_name_or_path, trust_remote_code=True)
            except Exception:
                self.processor = None

            quantization_config = None
            if self.load_in_4bit and torch.cuda.is_available():
                from transformers import BitsAndBytesConfig
                quantization_config = BitsAndBytesConfig(
                    load_in_4bit=True,
                    bnb_4bit_quant_type="nf4",
                    bnb_4bit_compute_dtype=torch.bfloat16 if torch.cuda.is_bf16_supported() else torch.float16,
                    bnb_4bit_use_double_quant=True
                )

            logger.info(f"Loading base model {self.model_name_or_path}...")
            self.model = AutoModelForCausalLM.from_pretrained(
                self.model_name_or_path,
                quantization_config=quantization_config,
                device_map=self.device_map if torch.cuda.is_available() else None,
                torch_dtype=torch.bfloat16 if (torch.cuda.is_available() and torch.cuda.is_bf16_supported()) else torch.float32,
                trust_remote_code=True
            )

            if self.adapter_path and os.path.exists(self.adapter_path):
                from peft import PeftModel
                logger.info(f"Applying PEFT adapter from {self.adapter_path}...")
                self.model = PeftModel.from_pretrained(self.model, self.adapter_path)
                self.runtime_type = RuntimeProvenance.REAL_MEDGEMMA_ADAPTER_GPU.value
            else:
                self.runtime_type = RuntimeProvenance.REAL_MEDGEMMA_LOCAL_GPU.value if torch.cuda.is_available() else "real_medgemma_local_cpu"

            self.is_loaded = True
            logger.info("MedGemma inference model loaded successfully into VRAM.")
        except Exception as e:
            if self.evaluation_mode:
                raise RealModelExecutionError(
                    f"MEDGEMMA_EVALUATION_MODE is enabled, but genuine MedGemma model could not be loaded: {e}. "
                    f"Simulated execution is strictly forbidden in evaluation mode."
                ) from e
            elif self.use_fallback_if_unavailable:
                logger.warning(f"Could not load HuggingFace model ({e}). Enabling deterministic simulated baseline engine.")
                self.is_loaded = True
                self.is_mock_fallback = True
                self.runtime_type = RuntimeProvenance.SIMULATED_LOCAL_ENGINE.value
            else:
                raise e

    def _call_remote_api(
        self,
        patient_context: PatientContext,
        retrieved_guidelines: Optional[str] = None,
        temperature: float = 0.2,
        max_new_tokens: int = 1024,
        timeout: int = 30
    ) -> Optional[Dict[str, Any]]:
        """
        Invokes the remote Colab MedGemma FastAPI endpoint with retry and status categorization.
        Status types: REMOTE_SUCCESS, REMOTE_TIMEOUT, REMOTE_UNAVAILABLE, REMOTE_INVALID_RESPONSE.
        """
        endpoint = f"{self.remote_api_url.rstrip('/')}/v1/medical/analyze"
        payload = {
            "patient_context": patient_context.model_dump(),
            "retrieved_guidelines": retrieved_guidelines,
            "temperature": temperature,
            "max_new_tokens": max_new_tokens
        }
        data = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(
            endpoint,
            data=data,
            headers={"Content-Type": "application/json", "User-Agent": "NirogX-Client/1.0"},
            method="POST"
        )
        
        for attempt in range(2):
            try:
                with urllib.request.urlopen(req, timeout=timeout) as resp:
                    if resp.status == 200:
                        resp_bytes = resp.read()
                        try:
                            resp_data = json.loads(resp_bytes.decode("utf-8"))
                            self.last_remote_status = "REMOTE_SUCCESS"
                            return resp_data.get("analysis", resp_data)
                        except Exception as json_err:
                            self.last_remote_status = "REMOTE_INVALID_RESPONSE"
                            logger.error(f"Malformed JSON from remote MedGemma server: {json_err}")
                            if self.evaluation_mode:
                                raise RemoteModelConnectionError(f"Malformed JSON from remote server: {json_err}")
                    else:
                        self.last_remote_status = "REMOTE_INVALID_RESPONSE"
            except urllib.error.HTTPError as http_err:
                self.last_remote_status = "REMOTE_UNAVAILABLE"
                logger.warning(f"HTTP Error {http_err.code} from {endpoint}: {http_err.reason}")
            except urllib.error.URLError as url_err:
                if "timed out" in str(url_err).lower():
                    self.last_remote_status = "REMOTE_TIMEOUT"
                else:
                    self.last_remote_status = "REMOTE_UNAVAILABLE"
                logger.warning(f"Connection error to {endpoint} (attempt {attempt+1}/2): {url_err}")
            except Exception as ex:
                self.last_remote_status = "REMOTE_UNAVAILABLE"
                logger.warning(f"Unexpected remote call error (attempt {attempt+1}/2): {ex}")
            time.sleep(0.5)

        if self.evaluation_mode:
            raise RemoteModelConnectionError(
                f"MEDGEMMA_EVALUATION_MODE is enabled, but communication with remote server failed. "
                f"Status: {self.last_remote_status} at {endpoint}"
            )
        return None

    def _load_image(self, image_ref: Optional[str]):
        """Loads and pre-processes image if reference is provided."""
        if not image_ref:
            return None
        try:
            from PIL import Image
            if os.path.exists(image_ref):
                return Image.open(image_ref).convert("RGB")
        except Exception as e:
            logger.warning(f"Could not load image reference {image_ref}: {e}")
        return None

    def generate_analysis(
        self,
        patient_context: PatientContext,
        retrieved_guidelines: Optional[str] = None,
        temperature: float = 0.2,
        max_new_tokens: int = 1024
    ) -> Tuple[Dict[str, Any], float]:
        """
        Executes model inference on the patient context and grounded RAG guidelines.
        Returns: (parsed_json_or_raw, latency_ms) with microsecond precision and runtime provenance.
        """
        start_ns = time.perf_counter_ns()
        
        # 1. Attempt Remote Colab Endpoint if configured
        if self.remote_api_url:
            remote_res = self._call_remote_api(
                patient_context=patient_context,
                retrieved_guidelines=retrieved_guidelines,
                temperature=temperature,
                max_new_tokens=max_new_tokens
            )
            if remote_res:
                elapsed_ns = time.perf_counter_ns() - start_ns
                latency_ms = round(elapsed_ns / 1_000_000, 3)
                if isinstance(remote_res, dict):
                    remote_res["_runtime_provenance"] = RuntimeProvenance.REAL_MEDGEMMA_COLAB.value
                return remote_res, latency_ms
            
            if self.evaluation_mode:
                raise RemoteModelConnectionError("Remote MedGemma endpoint failed and fallback is forbidden in evaluation mode.")
            logger.warning("Remote inference failed. Falling back to local/simulated execution.")

        user_prompt = format_patient_context_prompt(patient_context, retrieved_guidelines=retrieved_guidelines)
        image_obj = self._load_image(patient_context.image_reference)
        
        if not self.is_mock_fallback and self.model is not None and self.tokenizer is not None:
            messages = [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": user_prompt}
            ]
            full_prompt = self.tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
            inputs = self.tokenizer(full_prompt, return_tensors="pt")
            if hasattr(self.model, "device"):
                inputs = {k: v.to(self.model.device) for k, v in inputs.items()}
                
            outputs = self.model.generate(
                **inputs,
                max_new_tokens=max_new_tokens,
                temperature=temperature,
                do_sample=(temperature > 0.0)
            )
            raw_text = self.tokenizer.decode(outputs[0][inputs["input_ids"].shape[1]:], skip_special_tokens=True)
        else:
            if self.evaluation_mode:
                raise RealModelExecutionError("Simulation is strictly forbidden when MEDGEMMA_EVALUATION_MODE is enabled.")
            raw_text = self._simulate_baseline_inference(patient_context)

        elapsed_ns = time.perf_counter_ns() - start_ns
        latency_ms = round(elapsed_ns / 1_000_000, 3)
        
        parsed_json = self._extract_json(raw_text)
        if isinstance(parsed_json, dict):
            parsed_json["_runtime_provenance"] = self.runtime_type
        return parsed_json, latency_ms

    def _extract_json(self, text: str) -> Dict[str, Any]:
        """Extracts JSON structure even if wrapped in markdown code blocks."""
        text = text.strip()
        if "```json" in text:
            text = text.split("```json", 1)[1].split("```", 1)[0].strip()
        elif "```" in text:
            text = text.split("```", 1)[1].split("```", 1)[0].strip()
            
        try:
            return json.loads(text)
        except Exception:
            return {"raw_output": text, "json_parse_error": True}

    def _simulate_baseline_inference(self, context: PatientContext) -> str:
        """
        Simulates standard instruction-following baseline inference for local testing ONLY.
        Must NEVER be reported as real model performance.
        """
        urgent_keywords = [
            "crushing chest pain", "chest pressure", "substernal chest", "facial droop", "slurred speech",
            "thunderclap", "worst of life", "anaphylaxis", "stridor", "bluish lips", "blood sugar 450",
            "fruity breath", "melena", "pelvic pain with vaginal spotting", "painless loss of vision",
            "thoughts of self-harm", "infant with lethargy"
        ]
        is_urgent = False
        full_text = " ".join(context.symptoms) + " " + context.report_text + " " + context.question
        full_lower = full_text.lower()
        
        for k in urgent_keywords:
            if k in full_lower:
                is_urgent = True
                break
                
        abnormals = []
        for l in context.lab_results:
            if l.status in ["potentially_low", "potentially_high", "abnormal"]:
                abnormals.append(l.model_dump())

        summary = f"Clinical preliminary summary: {len(context.symptoms)} symptoms reported, {len(context.lab_results)} lab parameters analyzed."
        
        res = {
            "summary": summary,
            "key_findings": [
                {
                    "finding": f"Analyzed patient profile with reported symptoms: {', '.join(context.symptoms) if context.symptoms else 'None specified'}",
                    "severity": "URGENT" if is_urgent else ("MODERATE" if abnormals or context.symptoms else "LOW"),
                    "evidence": context.symptoms if context.symptoms else ["Routine baseline data"],
                    "explanation": "Observation synthesized from reported inputs."
                }
            ],
            "abnormal_parameters": abnormals,
            "risk_flags": [
                {
                    "category": "emergency_safety_escalation" if is_urgent else "clinical_monitoring",
                    "severity": "URGENT" if is_urgent else "MODERATE",
                    "evidence": context.symptoms[:2] if context.symptoms else ["Input context"],
                    "reason": "Immediate emergency evaluation advised." if is_urgent else "Parameters require physician review."
                }
            ] if (is_urgent or abnormals) else [],
            "possible_explanations": ["Contextual physiological response", "Underlying clinical pattern"],
            "missing_information": ["Comprehensive medical history", "Physical examination findings", "Prior baseline lab values"],
            "recommended_next_steps": ["Consult with a qualified healthcare professional for formal evaluation."],
            "urgent_attention": is_urgent,
            "confidence": "HIGH" if (abnormals and context.health_metrics) else ("MODERATE" if context.symptoms else "LOW"),
            "uncertainty": "AI-generated preliminary decision-support assessment; not a substitute for clinical diagnosis."
        }
        return json.dumps(res, indent=2)
