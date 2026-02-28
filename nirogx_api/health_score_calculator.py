from models import UserVitalsPayload, ActivityLevelEnum

class HealthScoreCalculator:
    def __init__(self):
        # Maximum points allocated per category (Total = 100)
        self.MAX_AGE_SCORE = 20.0
        self.MAX_BMI_SCORE = 25.0
        self.MAX_HR_SCORE = 20.0
        self.MAX_SLEEP_SCORE = 15.0
        self.MAX_ACTIVITY_SCORE = 20.0

        # Base optimal values for calculation
        self.OPTIMAL_AGE = 20.0
        self.OPTIMAL_BMI = 22.0
        self.OPTIMAL_HR = 70.0
        self.OPTIMAL_SLEEP = 8.0

        # Activity level scoring mapping
        self.ACTIVITY_SCORES = {
            ActivityLevelEnum.sedentary: 0.0,
            ActivityLevelEnum.light: 5.0,
            ActivityLevelEnum.moderate: 10.0,
            ActivityLevelEnum.active: 15.0,
            ActivityLevelEnum.very_active: 20.0,
            # Fallbacks as standard strings in case Enum is bypassed during tests
            "sedentary": 0.0,
            "light": 5.0,
            "moderate": 10.0,
            "active": 15.0,
            "very_active": 20.0,
        }

    def calculate_score(self, vitals: UserVitalsPayload) -> float:
        """
        Calculates an overall health score (0-100) based on vital deviations.
        """
        
        # 1. Age Score: Gradual penalty as age increases past 20.
        # Formula: $max(0, 20 - (Age - 20) \times 0.3)$
        age_penalty = max(0.0, (vitals.age - self.OPTIMAL_AGE) * 0.3)
        age_score = max(0.0, self.MAX_AGE_SCORE - age_penalty)

        # 2. BMI Score: Penalty for distance from optimal BMI of 22.
        # Formula: $max(0, 25 - |BMI - 22| \times 1.5)$
        bmi_penalty = abs(vitals.bmi - self.OPTIMAL_BMI) * 1.5
        bmi_score = max(0.0, self.MAX_BMI_SCORE - bmi_penalty)

        # 3. Heart Rate Score: Penalty for distance from optimal HR of 70.
        # Formula: $max(0, 20 - |HR - 70| \times 0.5)$
        hr_penalty = abs(vitals.heart_rate - self.OPTIMAL_HR) * 0.5
        hr_score = max(0.0, self.MAX_HR_SCORE - hr_penalty)

        # 4. Sleep Score: Penalty for distance from 8 hours of sleep.
        # Formula: $max(0, 15 - |Sleep - 8| \times 4.0)$
        sleep_penalty = abs(vitals.sleep_hours - self.OPTIMAL_SLEEP) * 4.0
        sleep_score = max(0.0, self.MAX_SLEEP_SCORE - sleep_penalty)

        # 5. Activity Score: Direct lookup
        activity_level_key = getattr(vitals.activity_level, "value", vitals.activity_level)
        activity_score = self.ACTIVITY_SCORES.get(activity_level_key, 0.0)

        # Aggregate Total Score
        total_score = age_score + bmi_score + hr_score + sleep_score + activity_score
        
        # Ensure it stays bounded strictly between 0 and 100
        total_score = max(0.0, min(100.0, total_score))

        return round(total_score, 2)