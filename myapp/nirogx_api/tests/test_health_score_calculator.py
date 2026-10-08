import pytest
from health_score_calculator import HealthScoreCalculator
from models import UserVitalsPayload, ActivityLevelEnum

@pytest.fixture
def calculator():
    return HealthScoreCalculator()

def test_calculate_score_young_healthy(calculator: HealthScoreCalculator):
    payload = UserVitalsPayload(
        age=25,
        bmi=22.0,
        heart_rate=70,
        sleep_hours=8.0,
        activity_level=ActivityLevelEnum.active
    )
    score = calculator.calculate_score(payload)
    assert 80 < score <= 100

def test_calculate_score_middle_aged_sedentary(calculator: HealthScoreCalculator):
    payload = UserVitalsPayload(
        age=45,
        bmi=28.0,
        heart_rate=85,
        sleep_hours=6.0,
        activity_level=ActivityLevelEnum.sedentary
    )
    score = calculator.calculate_score(payload)
    assert 40 < score < 70

def test_calculate_score_older_unhealthy(calculator: HealthScoreCalculator):
    payload = UserVitalsPayload(
        age=70,
        bmi=35.0,
        heart_rate=95,
        sleep_hours=5.0,
        activity_level=ActivityLevelEnum.sedentary
    )
    score = calculator.calculate_score(payload)
    assert 0 < score < 40