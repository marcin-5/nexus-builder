import pytest
import nexus_builder


def test_sum_as_string():
    assert nexus_builder.sum_as_string(1, 1) == "2"
