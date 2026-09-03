import math
from typing import Tuple, Dict, Any

def wilson_score_interval(successes: int, total: int, confidence: float = 0.95) -> Tuple[float, float, float]:
    """
    Calculates the point estimate and Wilson score 95% confidence interval for a binomial proportion.
    Returns: (point_estimate_pct, lower_bound_pct, upper_bound_pct)
    """
    if total <= 0:
        return 0.0, 0.0, 0.0

    p = successes / total
    z = 1.95996  # 95% confidence standard normal quantile

    denominator = 1 + (z**2) / total
    centre_adjusted_probability = p + (z**2) / (2 * total)
    adjusted_std_dev = math.sqrt((p * (1 - p) + (z**2) / (4 * total)) / total)

    lower = (centre_adjusted_probability - z * adjusted_std_dev) / denominator
    upper = (centre_adjusted_probability + z * adjusted_std_dev) / denominator

    lower = max(0.0, lower)
    upper = min(1.0, upper)

    return (
        round(p * 100, 2),
        round(lower * 100, 2),
        round(upper * 100, 2)
    )

def format_stat_with_ci(successes: int, total: int) -> str:
    p, low, high = wilson_score_interval(successes, total)
    return f"{successes}/{total} ({p}%, 95% CI: [{low}%, {high}%])"
