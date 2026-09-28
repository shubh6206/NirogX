import time
import pytest
from ai.inference.profiler import LatencyProfiler

def test_latency_profiler_phase_recording():
    profiler = LatencyProfiler()
    
    profiler.start_phase("preprocessing")
    time.sleep(0.005)
    profiler.end_phase()
    
    profiler.start_phase("gate1_safety")
    time.sleep(0.002)
    profiler.end_phase()
    
    profiler.start_phase("rag_retrieval")
    time.sleep(0.003)
    profiler.end_phase()
    
    breakdown = profiler.get_breakdown()
    assert "preprocessing_ms" in breakdown
    assert "gate1_safety_ms" in breakdown
    assert "rag_retrieval_ms" in breakdown
    assert "total_api_latency_ms" in breakdown
    assert breakdown["preprocessing_ms"] > 0
    assert breakdown["total_api_latency_ms"] >= (
        breakdown["preprocessing_ms"] + breakdown["gate1_safety_ms"] + breakdown["rag_retrieval_ms"]
    )
