from datetime import datetime, timezone
import logging

from app.cycle_service import get_cycle_context, CyclePhase
from app.risk_service import analyze_skin_risk, safe_phase

logger = logging.getLogger("hermona.notifications")

MODEL_VERSION = "risk_engine_v5.3"

DEFAULT_CYCLE_MAP = {
    CyclePhase.MENSTRUATION: 0.95,
    CyclePhase.FOLLICULAR:   0.90,
    CyclePhase.OVULATION:    1.10,
    CyclePhase.LUTEAL:       1.25
}


def check_smart_notifications(user_data, latest_prediction=None):
    """
    Academic-Grade Decision Engine (v5.3).
    Pipeline Stages:
        1. MODEL: Contextual risk analysis
        2. DECISION: Hormonal modulation & Scoring
        3. RUNTIME: Notification generation & Logging
    """

    notifications = []
    user_id = user_data.get("uid", "unknown")
    today = datetime.now(timezone.utc).strftime("%Y%m%d")

    # ── State Initialization ───────────────────────────────────────────────
    ctx = None
    res = None

    cycle_status = "FALLBACK"
    risk_band    = "STABLE_RISK"
    model_status = "OK"
    is_fallback  = False
    
    decision_score = 0.0
    impact_trace   = [] # Structured (layer, feature, value, step)

    try:
        # ── STAGE 1: MODEL (Contextual Risk Analysis) ─────────────────────
        ctx = get_cycle_context(
            user_data.get("lastPeriodsDate"),
            user_data.get("lastCyclesDuration")
        )

        if ctx:
            cycle_status = "OK"
            impact_trace.append({
                "layer": "MODEL",
                "feature": "hormonal_context",
                "value": {"day": ctx.day, "phase": ctx.phase.value},
                "step": 1
            })
        else:
            impact_trace.append({
                "layer": "MODEL",
                "feature": "hormonal_context",
                "value": "MISSING",
                "step": 1
            })

        current_phase = safe_phase(ctx.phase if ctx else CyclePhase.FOLLICULAR)

        # Input validation safety BEFORE execution
        if not latest_prediction or "riskScore" not in latest_prediction:
            model_status = "MISSING_INPUT"
            is_fallback  = True
            res = _default_risk_result()
        else:
            res = analyze_skin_risk(latest_prediction, current_phase)
            model_status = "OK"

        if is_fallback:
            impact_trace.append({"layer": "MODEL", "feature": "mode", "value": "fallback_execution", "step": 2})
        
        impact_trace.append({"layer": "MODEL", "feature": "raw_risk", "value": round(res.raw_risk, 3), "step": 3})
        impact_trace.append({"layer": "MODEL", "feature": "confidence", "value": res.confidence, "step": 4})

        # ── STAGE 2: DECISION (Hormonal Modulation & Scoring) ─────────────
        cycle_mod_map = user_data.get("cycle_weights", DEFAULT_CYCLE_MAP)

        # Simplified lookup (current_phase is already a CyclePhase)
        cycle_mod = cycle_mod_map.get(current_phase, 1.0)

        # Decision scoring (normalized, multiplicative)
        base = res.ui_risk
        decision_score = 0.0 if is_fallback else round(min(base * cycle_mod * res.confidence, 1.0), 3)

        # Quantitative drift analysis (always safe via res)
        drift = float(getattr(res, "drift", 0) or 0)

        if not is_fallback:
            if drift > 0.2:   risk_band = "HIGH_VARIANCE_INCREASE"
            elif drift > 0:   risk_band = "INCREASED_RISK"
            elif drift < 0:   risk_band = "DECREASED_RISK"
            else:             risk_band = "STABLE_RISK"
            
            impact_trace.append({
                "layer": "DECISION",
                "feature": "hormonal_modulation",
                "value": {"multiplier": cycle_mod, "delta": round(res.adjusted_risk - res.raw_risk, 3)},
                "step": 5
            })
        else:
            risk_band = "STABLE_RISK"

        # ── STAGE 3: RUNTIME (Notification Generation & Trace) ────────────
        
        # Luteal Entry Notification
        if ctx and ctx.is_luteal_entry:
            notifications.append({
                "id": f"luteal_{user_id}_{ctx.day}",
                "title": "Protection Hormonale Active",
                "body": "Votre cycle influence votre peau. Routine adaptée recommandée.",
                "type": "CYCLE",
                "priority": "HIGH"
            })

        # IA Risk Notification
        if res.final_level in ("HIGH", "CRITICAL"):
            notifications.append({
                "id": f"risk_{res.final_level.lower()}_{user_id}_{today}",
                "title": f"Risque {res.final_level}",
                "body": res.explanation,
                "type": "RISK",
                "priority": res.final_level # Uppercase standard
            })

        # ── Logging (Scientific Structured Logs) ──────────────────────────
        logger.info({
            "event": "engine_check_v5_3",
            "user": user_id,
            "version": MODEL_VERSION,
            "status": model_status,
            "is_fallback": is_fallback,
            "decision": {
                "score": decision_score,
                "band": risk_band,
                "drift": drift
            }
        })

    except Exception as e:
        logger.error({"event": "engine_error", "detail": str(e)})
        impact_trace.append({"layer": "RUNTIME", "feature": "error", "value": str(e), "step": 99})
        model_status = "ERROR"

    # ── Safe fallback metadata ─────────────────────────────────────────────
    safe_res = res or _default_risk_result()

    return {
        "notifications": notifications,
        "meta": {
            "status": cycle_status,
            "model_status": model_status,
            "model_version": MODEL_VERSION,
            "is_fallback": is_fallback,
            "model": {
                "raw_risk":      safe_res.raw_risk,
                "adjusted_risk": safe_res.adjusted_risk,
                "confidence":    safe_res.confidence
            },
            "decision": {
                "final_level":    safe_res.final_level,
                "decision_score": decision_score,
                "risk_band":      risk_band
            },
            "explainability": {
                "trace": sorted(impact_trace, key=lambda x: x["step"]),
                "explanation": safe_res.explanation
            }
        }
    }


def _default_risk_result():
    from app.risk_service import RiskResult
    return RiskResult(
        raw_risk=0.0, adjusted_risk=0.0, ui_risk=0.0,
        ml_level="LOW", final_level="LOW",
        drift=0, confidence=1.0, 
        explanation="Fallback mode: missing or malformed prediction data"
    )
