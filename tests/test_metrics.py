import pytest

from giraffe.metrics import semantic_error_rate


@pytest.mark.parametrize(
    ("errors", "expected"),
    [
        ([False, False], 0.0),
        ([True, True], 1.0),
        ([True, False, True], 2 / 3),
    ],
)
def test_semantic_error_rate(errors: list[bool], expected: float) -> None:
    assert semantic_error_rate(errors) == pytest.approx(expected)


def test_empty_evaluations() -> None:
    with pytest.raises(ValueError, match="At least one evaluation is required"):
        semantic_error_rate([])
