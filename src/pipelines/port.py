import importlib
from pathlib import Path
from typing import Any

from pipelines import adapters, paths

"a task is an action with a name and dependencies"

root_module = "pipelines.compilers.{}"


class Port:
    def compile(
        self,
        adapter: adapters.Adapters,
    ) -> str:
        # TODO: these will eventually need to be injected probably
        compiler_module = importlib.import_module(root_module.format(adapter.value))
        compiler = getattr(compiler_module, adapter.value.capitalize())
        return compiler().compile(object=self)

    @classmethod
    def decompile(cls, artifact: Any, adapter: adapters.Adapters):
        # TODO: these will eventually need to be injected probably
        compiler_module = importlib.import_module(root_module.format(adapter.value))
        compiler = getattr(compiler_module, adapter.value.capitalize())
        return compiler().decompile(artifact=artifact, object=cls)

    @classmethod
    def load(
        cls,
        name: str,
        adapter: adapters.Adapters | None = None,
        pipeline_directory: Path | None = None,
    ):
        # TODO matches save exactly, needs to stay in sync
        pipeline_directory = pipeline_directory or paths.get_path("pipelines")
        adapter = adapter or adapters.Adapters.YAML
        artifact_candidates = list(
            pipeline_directory.glob(f"*/{name}.*")
        )  # TODO: need helper for finding config by name
        if len(artifact_candidates) > 1:
            msg = f"More than one config found matching the name: {name}. Found: {artifact_candidates}."
            raise ValueError(msg)
        if len(artifact_candidates) == 0:
            msg = f"No configs found matching the name: {name}."
            raise ValueError(msg)

        artifact_path = artifact_candidates[0]

        with artifact_path.open() as f:
            artifact = f.read()
        return cls.decompile(artifact=artifact, adapter=adapter)
