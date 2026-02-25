
from models import UserVitalsPayload

class HealthScoreCalculator:
    def _get_dynamic_weights(self, age: int) -> tuple[float, float, float]:
        """
        Dynamically determine weights based on age.
        These are example values and should be refined with domain expertise.
        """
        if age < 30:
            return (0.4, 0.4, 0.2)  # Lifestyle is more important
        elif 30 <= age < 60:
            return (0.5, 0.3, 0.2)  # Vitals become more important
        else:
            return (0.6, 0.2, 0.2)  # Vitals are most important

    def _normalize_value(self, value, min_val, max_val):
        """Normalize a value to a 0-1 scale."""
        return max(0, min(1, (value - min_val) / (max_val - min_val)))

    def calculate_score(self, payload: UserVitalsPayload) -> float:
        w1, w2, w3 = self._get_dynamic_weights(payload.age)

        # Vitals Score (example logic)
        # BMI: Ideal is 18.5-24.9. Score is inverted; lower is better if outside range.
        bmi_score = 1 - self._normalize_value(abs(payload.bmi - 21.7), 0, 15)
        # Heart Rate: Ideal is 60-100 bpm at rest.
        hr_score = 1 - self._normalize_value(abs(payload.heart_rate - 80), 0, 40)
        vitals_score = (bmi_score + hr_score) / 2

        # Lifestyle Score (example logic)
        # Sleep: Ideal is 7-9 hours.
        sleep_score = self._normalize_value(payload.sleep_hours, 4, 8)
        # Activity Level: Map categorical to numerical.
        activity_map = {"sedentary": 0.2, "light": 0.5, "moderate": 0.8, "active": 1.0}
        activity_score = activity_map.get(payload.activity_level.lower(), 0.5)
        lifestyle_score = (sleep_score + activity_score) / 2
        
        # Risk Factors (example logic)
        # Age: Higher age is a risk factor.
        age_risk = self._normalize_value(payload.age, 20, 80)
        # BMI: Very high or low BMI is a risk.
        bmi_risk = 1 - bmi_score # Inverted bmi_score
        risk_factors_score = (age_risk + bmi_risk) / 2

        # Final Health Score Calculation
        raw_score = (w1 * vitals_score) + (w2 * lifestyle_score) - (w3 * risk_factors_score)

        # Normalize to a score out of 100
        final_score = max(0, min(100, raw_score * 100))
        
        return round(final_score, 2)

