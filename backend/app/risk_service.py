from dataclasses import dataclass
import logging
from app.cycle_service import CyclePhase

logger = logging.getLogger("hermona.risk")

# ── Constants ─────────────────────────────────────────────────────────────────

PHASE_MULTIPLIER: dict[CyclePhase, float] = {
    CyclePhase.MENSTRUATION: 1.0,
    CyclePhase.FOLLICULAR:   0.9,
    CyclePhase.OVULATION:    1.1,
    CyclePhase.LUTEAL:       1.25,
}

LEVEL_SCORE: dict[str, int] = {
    "LOW": 0, "MEDIUM": 1, "HIGH": 2, "CRITICAL": 3
}

PHASE_EXPLANATION: dict[CyclePhase, str] = {
    CyclePhase.MENSTRUATION: "Menstruation increases skin sensitivity and barrier weakness.",
    CyclePhase.FOLLICULAR:   "Follicular phase: oestrogen rise improves skin clarity.",
    CyclePhase.OVULATION:    "Ovulation: sebum production peaks, pore congestion risk.",
    CyclePhase.LUTEAL:       "Luteal phase increased sebaceous activity and inflammation sensitivity.",
}

# ── Domain object ─────────────────────────────────────────────────────────────

@dataclass(frozen=True)
class RiskResult:
    """
    Complete output of the Hormonal-Aware Risk Engine v2.
    Separates raw ML signal, hormonal adjustment, and UI-safe values.
    """
    raw_risk:      float   # Unmodified ML output
    adjusted_risk: float   # raw * phase_multiplier (internal, may exceed 1.0)
    ui_risk:       float   # min(adjusted_risk, 1.0) — safe for display
    ml_level:      str     # Label based on raw_risk
    final_level:   str     # Label based on ui_risk
    drift:         int     # Ordinal delta: LEVEL_SCORE[final] - LEVEL_SCORE[ml]
    confidence:    float   # Proxy: 1 - |adjusted - raw| / max amplification
    explanation:   str     # Human-readable hormonal context


# ── Helpers ───────────────────────────────────────────────────────────────────

def safe_phase(value) -> CyclePhase:
    """
    Converts any phase representation to CyclePhase.
    Handles: CyclePhase.LUTEAL, 'LUTEAL', 'luteal', 'CyclePhase.LUTEAL'.
    Defaults to FOLLICULAR on any parse failure.
    """
    if isinstance(value, CyclePhase):
        return value
    try:
        raw = str(value).upper().replace('CYCLEPHASE.', '')
        return CyclePhase[raw]
    except (KeyError, AttributeError):
        logger.warning({"event": "phase_parse_error", "received": str(value)})
        return CyclePhase.FOLLICULAR


def _score_to_level(score: float) -> str:
    if score >= 0.85: return "CRITICAL"
    if score >= 0.70: return "HIGH"
    if score >= 0.40: return "MEDIUM"
    return "LOW"


def _confidence(raw: float, adjusted: float, max_mult: float = 1.25) -> float:
    """
    Confidence proxy: high when cycle amplification is small (prediction is stable).
    Low when hormonal context drastically changes the outcome.
    """
    max_possible_delta = raw * (max_mult - 1.0)
    if max_possible_delta == 0:
        return 1.0
    actual_delta = abs(adjusted - raw)
    return round(max(0.0, 1.0 - actual_delta / max_possible_delta), 3)


# ── Main engine ───────────────────────────────────────────────────────────────

def analyze_skin_risk(
    latest_prediction,
    phase: CyclePhase = CyclePhase.FOLLICULAR
) -> RiskResult:
    """
    Hormonal-Aware Risk Engine v2.

    Layers:
      1. ML Score  → ml_level           (raw, pre-phase)
      2. Phase Adjustment               (hormonal multiplier, internal)
      3. Final Decision Level           (from UI-clamped score)
      4. Drift Score                    (ordinal: how much cycle changed outcome)
      5. Confidence                     (stability of prediction under cycle context)
      6. Explanation                    (human-readable hormonal rationale)
    """
    # Type guard
    phase = safe_phase(phase)

    # No data
    if not latest_prediction or not isinstance(latest_prediction, dict):
        return _empty_result(phase)

    # Missing key warning
    if 'riskScore' not in latest_prediction:
        logger.warning({"event": "risk_analysis", "result": "missing_riskScore"})
        return _empty_result(phase)

    raw_risk = float(latest_prediction['riskScore'])

    # Layer 1: ML label
    ml_level = _score_to_level(raw_risk)

    # Layer 2: hormonal adjustment (internal, unclamped to preserve full signal)
    multiplier    = PHASE_MULTIPLIER.get(phase, 1.0)
    adjusted_risk = raw_risk * multiplier

    # Layer 3: UI-safe risk and final decision
    ui_risk     = min(adjusted_risk, 1.0)
    final_level = _score_to_level(ui_risk)

    # Layer 4: drift (ordinal delta)
    drift = LEVEL_SCORE[final_level] - LEVEL_SCORE[ml_level]

    # Layer 5: confidence proxy
    confidence = _confidence(raw_risk, adjusted_risk)

    # Layer 6: explanation
    explanation = PHASE_EXPLANATION.get(phase, "")

    result = RiskResult(
        raw_risk=round(raw_risk, 3),
        adjusted_risk=round(adjusted_risk, 3),
        ui_risk=round(ui_risk, 3),
        ml_level=ml_level,
        final_level=final_level,
        drift=drift,
        confidence=confidence,
        explanation=explanation,
    )

    logger.info({
        "event":      "risk_analysis_v2",
        "phase":      phase.value,
        "multiplier": multiplier,
        **result.__dict__
    })

    return result


def _empty_result(phase: CyclePhase) -> RiskResult:
    return RiskResult(
        raw_risk=0.0, adjusted_risk=0.0, ui_risk=0.0,
        ml_level="LOW", final_level="LOW",
        drift=0, confidence=1.0,
        explanation=PHASE_EXPLANATION.get(phase, ""),
    )
