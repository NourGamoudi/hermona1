from datetime import datetime

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
    # 1. Extract inputs with production fallbacks
    lp_date = profile.get('lastPeriodsDate')
    last_cycles = profile.get('lastCyclesDuration', [28])
    cycle_length = int(sum(last_cycles) / len(last_cycles)) if last_cycles else 28
    m_duration = profile.get('menstruationDuration', 5)

    if not lp_date:
        # Fallback to today if missing, though it should be required
        lp_date = datetime.now().isoformat()

    # 2. Normalize lp_date
    if isinstance(lp_date, str):
        try:
            last_date = datetime.fromisoformat(lp_date.replace('Z', '+00:00'))
        except:
            last_date = datetime.strptime(lp_date[:10], "%Y-%m-%d")
    elif hasattr(lp_date, 'isoformat'):
        last_date = lp_date
    else:
        last_date = datetime.now()

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
    ovulation_day = cycle_length - 14

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
