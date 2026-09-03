import time
from typing import Dict, Any

class LatencyProfiler:
    """
    Sub-millisecond latency profiler for clinical pipeline observability.
    """
    def __init__(self):
        self.phase_times_ns: Dict[str, int] = {}
        self.active_phase: str = None
        self.phase_start_ns: int = 0
        self.total_start_ns: int = time.perf_counter_ns()

    def start_phase(self, phase_name: str):
        if self.active_phase:
            self.end_phase()
        self.active_phase = phase_name
        self.phase_start_ns = time.perf_counter_ns()

    def end_phase(self):
        if self.active_phase:
            elapsed_ns = time.perf_counter_ns() - self.phase_start_ns
            self.phase_times_ns[self.active_phase] = (
                self.phase_times_ns.get(self.active_phase, 0) + elapsed_ns
            )
            self.active_phase = None

    def get_breakdown(self) -> Dict[str, float]:
        if self.active_phase:
            self.end_phase()

        total_ns = time.perf_counter_ns() - self.total_start_ns
        breakdown = {
            f"{phase}_ms": round(ns / 1_000_000, 3)
            for phase, ns in self.phase_times_ns.items()
        }
        breakdown["total_api_latency_ms"] = round(total_ns / 1_000_000, 3)
        return breakdown
