"""Metrics for semantic evaluation of restored images."""

from collections.abc import Sequence


def semantic_error_rate(errors: Sequence[bool]) -> float:
    """Return the fraction of evaluations flagged as semantic errors."""
    if not errors:
        raise ValueError("At least one evaluation is required")
    return sum(errors) / len(errors)
