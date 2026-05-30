from datetime import datetime


def _first_present(profile: dict, keys: list, default=None):
    for key in keys:
        value = profile.get(key)
        if value is not None and value != "":
            return value
    return default


def _coerce_int(value, default: int, minimum: int = 1, maximum: int = 400) -> int:
    try:
        parsed = int(value)
    except (TypeError, ValueError):
        return default
    return max(minimum, min(maximum, parsed))


def _coerce_cycle_lengths(value) -> list:
    if isinstance(value, list):
        lengths = [_coerce_int(v, 28, 15, 120) for v in value]
        return [v for v in lengths if v > 0]
    if value is not None:
        return [_coerce_int(value, 28, 15, 120)]
    return [28]


def _parse_date(value):
    if not value:
        return datetime.now()
    if isinstance(value, str):
        try:
            return datetime.fromisoformat(value.replace("Z", "+00:00"))
        except ValueError:
            return datetime.strptime(value[:10], "%Y-%m-%d")
    if hasattr(value, "to_datetime"):
        return value.to_datetime()
    if hasattr(value, "isoformat"):
        return value
    return datetime.now()

def compute_cycle_state(profile: dict) -> dict:
    """
    CLINICAL ENGINE (RULE-BASED ESTIMATOR).
    Role: Deterministic estimation of the hormonal cycle state.
    Logic: Rule-based system using biological priors and user parameters.
    
    Clinical Hypotheses (Fallbacks):
    - cycleLength: 28 days (Standard Clinical Prior)
    - menstruationDuration: 5 days (Physiological Baseline)
    
    This module provides the deterministic pre-processing layer for the 
    Hybrid Clinical-ML Decision System.
    """
    profile = profile or {}

    # 1. Extract inputs with production fallbacks.
    # The app has used both singular and plural names across versions, so the
    # clinical engine accepts all known aliases and returns one canonical phase.
    lp_date = _first_present(profile, ["lastPeriodsDate", "lastPeriodDate", "last_period_date"])
    last_cycles = _coerce_cycle_lengths(_first_present(
        profile,
        ["lastCyclesDuration", "cycleDuration", "cycleLength", "cycle_length"],
        [28],
    ))
    cycle_length = int(sum(last_cycles) / len(last_cycles)) if last_cycles else 28
    m_duration = _coerce_int(
        _first_present(profile, ["menstruationDuration", "periodDuration", "menstruation_duration"], 5),
        5,
        1,
        10,
    )

    if not lp_date:
        # Fallback to today if missing, though it should be required
        lp_date = datetime.now().isoformat()

    # 2. Normalize lp_date
    last_date = _parse_date(lp_date)

    # 3. Date-only normalization (Ensuring both are naive for comparison)
    today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    
    # If last_date is aware, make it naive
    if last_date.tzinfo is not None:
        last_date = last_date.replace(tzinfo=None)
        
    last = last_date.replace(hour=0, minute=0, second=0, microsecond=0)

    # 4. Calculate cycleDay
    diff_days = (today - last).days
    day = (diff_days % cycle_length) + 1

    # 5. Ovulation Day
    ovulation_day = max(m_duration + 1, cycle_length - 14)

    # 6. Phase Mapping (STRICT SCIENTIFIC RULE)
    if day <= m_duration:
        phase = "menstrual"
    elif day < ovulation_day:
        phase = "follicular"
    elif day <= ovulation_day + 1:
        phase = "ovulatory"
    else:
        phase = "luteal"

    return {
        "cycleDay": day,
        "cyclePhase": phase,
        "ovulationDay": int(ovulation_day),
        "cycleLength": cycle_length,
        "menstruationDuration": m_duration
    }
