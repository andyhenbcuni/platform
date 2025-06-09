import os
import pathlib
import sys
from collections.abc import Callable, Generator
from typing import Any

import pytest

from pipelines import pipeline, task
from pipelines import trigger as trigger_port
from tests.pipeline_base import pipelines_helpers

TEST_ROOT = str(object=pathlib.Path(__file__).parent)
os.environ["ACTION_PATH"] = TEST_ROOT
sys.path.insert(0, TEST_ROOT)
os.environ["PYTHONPATH"] = str(TEST_ROOT)


# TODO: to get sub tasks (multiple at once)
@pytest.fixture(scope="function")
def get_stub_task() -> Generator[Callable[..., task.Task], Any, None]:
    def _stub_task(
        name: str | None = None,
        action: Callable[..., Any] | None = None,
        parameters: dict[str, Any] | None = None,
        depends_on: list[str] | None = None,
    ) -> task.Task:
        return task.Task(
            name=name or "stub_task",
            action=action or pipelines_helpers.stub_action,
            parameters=parameters or {},
            depends_on=depends_on or [],
        )

    yield _stub_task


@pytest.fixture(scope="function")
def get_stub_tasks() -> Generator[Callable[..., list[task.Task]], Any, None]:
    def _stub_tasks(
        n: int,
        connected: bool = False,
    ) -> list[task.Task]:
        return [
            task.Task(
                name=f"stub_task_{i}",
                action=pipelines_helpers.stub_action,
                depends_on=[f"stub_task_{i - 1}"] if i > 1 and connected else [],
            )
            for i in range(1, n + 1)
        ]

    yield _stub_tasks


@pytest.fixture(scope="function")
def get_stub_pipeline() -> Generator[Callable[..., pipeline.Pipeline], Any, None]:
    def _stub_pipeline(
        name: str | None = None,
        trigger: trigger_port.Trigger | None = None,
        tasks: list[task.Task] | None = None,
    ) -> pipeline.Pipeline:
        return pipeline.Pipeline(
            name=name or "stub_pipeline",
            trigger=trigger
            or trigger_port.CronTrigger(start_date="2000-01-01", schedule="0 12 * * *"),
            tasks=tasks or [],
        )

    yield _stub_pipeline
