import inspect
from collections.abc import Callable
from dataclasses import dataclass, field
from datetime import timedelta
from pathlib import Path
from typing import Any

from pipelines import port


@dataclass
class Task(port.Port):
    """a task is an action with a name and dependencies"""

    name: str
    action: Callable[..., Any] | None = field(default_factory=lambda: None)
    parameters: dict[str, Any] = field(default_factory=dict)
    depends_on: list[str] = field(default_factory=list)
    src: Path = Path(__file__).parent
    retries: int = 3
    retry_delay: timedelta = timedelta(minutes=1)

    def __eq__(self, other: object):
        self_action = (
            inspect.getsource(getattr(self, "action"))
            if self.action is not None
            else None
        )
        other_action = (
            inspect.getsource(getattr(other, "action"))
            if self.action is not None
            else None
        )
        if isinstance(other, type(self)) and all(
            [
                self.name == other.name,
                self_action == other_action,
                self.parameters == other.parameters,
                self.depends_on == other.depends_on,
                self.retries == other.retries,
                self.retry_delay == other.retry_delay,
            ]
        ):
            return True
        return False
