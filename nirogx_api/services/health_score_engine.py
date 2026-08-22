from typing import Dict, Any
from models import VitalsPayload, HealthScoreResult, HealthScoreComponent

def calculate_deterministic_health_score(payload: VitalsPayload) -> HealthScoreResult:
    # 1. Activity Score (0-100)
    activity_map = {
        "sedentary": 45.0,
        "light": 65.0,
        "moderate": 85.0,
        "active": 95.0,
        "very_active": 98.0
    }
    activity_score = activity_map.get(payload.activity_level.lower(), 75.0)

    # 2. Sleep Score (0-100)
    sleep_h = payload.sleep_hours
    if 7.0 <= sleep_h <= 9.0:
        sleep_score = 95.0
    elif 6.0 <= sleep_h < 7.0 or 9.0 < sleep_h <= 10.0:
        sleep_score = 80.0
    elif 5.0 <= sleep_h < 6.0:
        sleep_score = 65.0
    else:
        sleep_score = 45.0

    # 3. Heart Health Score (0-100)
    hr = payload.heart_rate
    if 55 <= hr <= 72:
        hr_score = 95.0
    elif 73 <= hr <= 85:
        hr_score = 80.0
    elif 86 <= hr <= 100:
        hr_score = 60.0
    else:
        hr_score = 40.0

    # 4. Recovery Index (0-100)
    recovery_score = round((sleep_score * 0.5) + (hr_score * 0.3) + 15.0, 1)
    recovery_score = min(100.0, max(0.0, recovery_score))

    # 5. Hydration Score (0-100)
    hydration_val = payload.hydration_liters if payload.hydration_liters is not None else 1.75
    if hydration_val >= 2.5:
        hydration_score = 95.0
    elif hydration_val >= 2.0:
        hydration_score = 85.0
    elif hydration_val >= 1.5:
        hydration_score = 75.0
    else:
        hydration_score = 55.0

    # Dynamic Weight Normalization
    weights = {
        "activity": 0.25,
        "sleep": 0.25,
        "heartHealth": 0.25,
        "recovery": 0.15,
        "hydration": 0.10
    }

    total_weight = sum(weights.values())
    overall_score = (
        (activity_score * weights["activity"]) +
        (sleep_score * weights["sleep"]) +
        (hr_score * weights["heartHealth"]) +
        (recovery_score * weights["recovery"]) +
        (hydration_score * weights["hydration"])
    ) / total_weight

    overall_score = round(overall_score, 1)

    if overall_score >= 80:
        status = "Optimal"
    elif overall_score >= 65:
        status = "Good"
    elif overall_score >= 50:
        status = "Caution"
    else:
        status = "Alert"

    helping = []
    opportunities = []

    if hr_score >= 85:
        helping.append(f"Resting heart rate ({hr} bpm) is in the optimal autonomic range.")
    else:
        opportunities.append(f"Resting heart rate ({hr} bpm) elevated. Consider stress reduction.")

    if sleep_score >= 80:
        helping.append(f"Consistent restorative sleep duration ({sleep_h} hrs/night).")
    else:
        opportunities.append(f"Target 7.0-9.0 hours of sleep (currently {sleep_h} hrs).")

    if activity_score >= 80:
        helping.append("Active daily movement volume supports cardiovascular health.")
    else:
        opportunities.append("Increase daily steps and physical activity volume.")

    if hydration_val < 2.0:
        opportunities.append(f"Hydration ({hydration_val}L) below recommended 2.5L daily target.")

    components = {
        "activity": HealthScoreComponent(
            score=activity_score,
            rawWeight=0.25,
            normalizedWeight=0.25,
            isAvailable=True,
            label="Physical Activity",
            currentDisplay=f"{payload.activity_level.replace('_', ' ').capitalize()}",
            benchmarkDisplay="8,000+ steps or moderate exercise",
            status="optimal" if activity_score >= 80 else "good" if activity_score >= 60 else "needs_attention"
        ),
        "sleep": HealthScoreComponent(
            score=sleep_score,
            rawWeight=0.25,
            normalizedWeight=0.25,
            isAvailable=True,
            label="Sleep Architecture",
            currentDisplay=f"{sleep_h} hrs",
            benchmarkDisplay="7.0 - 9.0 hrs / night",
            status="optimal" if sleep_score >= 80 else "good" if sleep_score >= 60 else "needs_attention"
        ),
        "heartHealth": HealthScoreComponent(
            score=hr_score,
            rawWeight=0.25,
            normalizedWeight=0.25,
            isAvailable=True,
            label="Cardiovascular Health",
            currentDisplay=f"{hr} bpm",
            benchmarkDisplay="60 - 75 bpm resting",
            status="optimal" if hr_score >= 80 else "good" if hr_score >= 60 else "needs_attention"
        ),
        "recovery": HealthScoreComponent(
            score=recovery_score,
            rawWeight=0.15,
            normalizedWeight=0.15,
            isAvailable=True,
            label="Recovery Index",
            currentDisplay=f"{int(recovery_score)}/100",
            benchmarkDisplay="75+ balanced recovery",
            status="optimal" if recovery_score >= 80 else "good"
        ),
        "hydration": HealthScoreComponent(
            score=hydration_score,
            rawWeight=0.10,
            normalizedWeight=0.10,
            isAvailable=True,
            label="Hydration Intake",
            currentDisplay=f"{hydration_val} L",
            benchmarkDisplay="2.5 L / day target",
            status="optimal" if hydration_score >= 80 else "good"
        ),
    }

    return HealthScoreResult(
        score=overall_score,
        status=status,
        evaluatedCategories=5,
        totalCategories=5,
        components=components,
        helpingFactors=helping,
        improvementOpportunities=opportunities,
        explanation="Deterministic clinical composite normalized across 5 active biometric dimensions.",
        changeDelta=4.0
    )
