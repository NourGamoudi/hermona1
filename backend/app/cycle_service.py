from datetime import datetime, timezone
from dataclasses import dataclass
from enum import Enum
import logging
import statistics

logger = logging.getLogger("hermona.cycle")


class CyclePhase(Enum):
    MENSTRUATION = "MENSTRUATION"
    FOLLICULAR   = "FOLLICULAR"
    OVULATION    = "OVULATION"
    LUTEAL       = "LUTEAL"


@dataclass(frozen=True)
class CycleContext:
    """
    Domain object encapsulating the complete hormonal state of a user.
    Based on a periodicity model (simplified assumption).
    For higher precision, cycle_len uses the median of past cycles.
    """
    day: int
    cycle_len: int
    phase: CyclePhase

    @property
    def ovulation(self) -> int:
        # Medical standard: ovulation is always ~14 days before next period
        return self.cycle_len - 14

    @property
    def luteal_start(self) -> int:
        return self.ovulation + 1

    @property
    def is_luteal_entry(self) -> bool:
        """
        True only if phase is LUTEAL AND we are in the first 3 days.
        Double guard: phase check prevents false positives if params change.
        """
        return (
            self.phase == CyclePhase.LUTEAL
            and self.day <= self.luteal_start + 3
        )


def get_cycle_context(last_period_date, cycles_duration=None) -> CycleContext:
    """
    Single entry point for hormonal state. Returns an immutable CycleContext.
    Uses median of past cycle durations to reduce the effect of outliers.
    """
    try:
        durations = cycles_duration or [28]
        # Median > mean for biological stability (outlier-resistant)
        cycle_len = round(statistics.median(durations))

        if not last_period_date:
            return CycleContext(day=1, cycle_len=cycle_len, phase=CyclePhase.FOLLICULAR)

        now = datetime.now(timezone.utc)
        if isinstance(last_period_date, str):
            last_date = datetime.fromisoformat(last_period_date.replace('Z', '+00:00'))
        else:
            last_date = (
                last_period_date if last_period_date.tzinfo
                else last_period_date.replace(tzinfo=timezone.utc)
            )

        diff  = max(0, (now - last_date).days)
        day   = (diff % cycle_len) + 1
        phase = _get_phase(day, cycle_len)

        logger.info({"event": "cycle_calculated", "day": day, "phase": phase.value, "cycle_len": cycle_len})
        return CycleContext(day=day, cycle_len=cycle_len, phase=phase)

    except Exception as e:
        logger.error({"event": "cycle_error", "detail": str(e)})
        return CycleContext(day=1, cycle_len=28, phase=CyclePhase.FOLLICULAR)


def _get_phase(day: int, cycle_len: int) -> CyclePhase:
    ovulation = cycle_len - 14
    if day <= 5:
        return CyclePhase.MENSTRUATION
    elif day < ovulation:
        return CyclePhase.FOLLICULAR
    elif day == ovulation:
        return CyclePhase.OVULATION
    else:
        return CyclePhase.LUTEAL
