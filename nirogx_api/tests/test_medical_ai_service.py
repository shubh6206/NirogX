import pytest
import json
from unittest.mock import patch, MagicMock
from models import SymptomPayload, ClinicalAssessment
from medical_ai_service import MedicalAIService

# --- Fixtures ---
@pytest.fixture
def ai_service():
    """Initializes the service once for all tests."""
    return MedicalAIService()

@pytest.fixture
def sample_payload():
    """A standard payload to use across tests."""
    return SymptomPayload(
        text="Severe headache and blurry vision",
        duration="3 hours"
    )

# --- Tests ---

@patch("medical_ai_service.genai.GenerativeModel.generate_content")
def test_analyze_symptoms_success(mock_generate, ai_service, sample_payload):
    """Test that valid JSON from Gemini is parsed into the Pydantic model correctly."""
    
    # 1. Arrange: Create a fake response that mimics the Gemini SDK object
    mock_response = MagicMock()
    # We supply a perfectly formatted JSON string just like Gemini would in JSON mode
    mock_response.text = json.dumps({
        "assessment": "Possible migraine or hypertension. Please consult a doctor.",
        "red_flags": ["Severe headache", "Blurry vision"],
        "confidence_score": 0.85
    })
    mock_generate.return_value = mock_response

    # 2. Act: Call your actual function
    result = ai_service.analyze_symptoms(sample_payload)

    # 3. Assert: Check if it populated the Pydantic model correctly
    assert isinstance(result, ClinicalAssessment)
    assert result.assessment == "Possible migraine or hypertension. Please consult a doctor."
    assert "Blurry vision" in result.red_flags
    assert result.confidence_score == 0.85
    
    # Verify the mock was actually called
    mock_generate.assert_called_once()


@patch("medical_ai_service.genai.GenerativeModel.generate_content")
def test_analyze_symptoms_invalid_json(mock_generate, ai_service, sample_payload):
    """Test that a hallucinated or malformed JSON response is caught safely."""
    
    # 1. Arrange: Gemini returns bad Markdown instead of raw JSON
    mock_response = MagicMock()
    mock_response.text = "```json\n{bad_data: missing quotes}\n```"
    mock_generate.return_value = mock_response

    # 2. Act
    result = ai_service.analyze_symptoms(sample_payload)

    # 3. Assert: Ensure it triggers the JSONDecodeError fallback
    assert "Error: AI provided an invalid response format" in result.assessment
    assert "System Error" in result.red_flags
    assert result.confidence_score == 0.0


@patch("medical_ai_service.genai.GenerativeModel.generate_content")
def test_analyze_symptoms_api_failure(mock_generate, ai_service, sample_payload):
    """Test that an API timeout or connection error doesn't crash the server."""
    
    # 1. Arrange: Force the mock to throw an Exception (like a network timeout)
    mock_generate.side_effect = Exception("503 Service Unavailable")

    # 2. Act
    result = ai_service.analyze_symptoms(sample_payload)

    # 3. Assert: Ensure the generic exception fallback handles it
    assert "An error occurred while analyzing the symptoms" in result.assessment
    assert result.red_flags == []
    assert result.confidence_score == 0.0