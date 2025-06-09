from collections.abc import Callable

import pytest

from src.pipelines import pipeline, task
from src.pipelines.compilers import databricks

# TODO: Add coverage for trigger, compute, and access

stub_deployment_args = databricks.DatabricksDeploymentArgs(
    google_service_account="stub",
    environment="stub",
    whl_path="stub",
    package_name="stub",
    configuration_item="stub",
    max_workers=2,
    service_now_id="stub",
    data_compliance="None",
    node_type_id="n2d-highmem-8",
    policy_id=None,
)


class TestPipeline:
    @pytest.mark.slow
    def test_can_compile_single_task(
        self,
        get_stub_task: Callable[..., task.Task],
        get_stub_pipeline: Callable[..., pipeline.Pipeline],
    ) -> None:
        compiler = databricks.Databricks()
        stub_task: task.Task = get_stub_task()
        stub_pipeline: pipeline.Pipeline = get_stub_pipeline(tasks=[stub_task])

        databricks_pipeline = compiler.compile(
            stub_pipeline, deploy_args=stub_deployment_args
        )

        assert len(databricks_pipeline.tasks) == 1
        databricks_task = databricks_pipeline.tasks[0]
        assert databricks_task.task_key == stub_task.name
        # TODO: increase coverage as implementation matures

    @pytest.mark.slow
    def test_can_compile_multiple_tasks(
        self,
        get_stub_tasks: Callable[..., list[task.Task]],
        get_stub_pipeline: Callable[..., pipeline.Pipeline],
    ) -> None:
        compiler = databricks.Databricks()
        stub_task, stub_task_2 = get_stub_tasks(n=2, connected=True)
        stub_pipeline: pipeline.Pipeline = get_stub_pipeline(
            tasks=[stub_task, stub_task_2]
        )

        databricks_pipeline = compiler.compile(
            stub_pipeline, deploy_args=stub_deployment_args
        )

        assert len(databricks_pipeline.tasks) == 2
        task_dict = {task.task_key: task for task in databricks_pipeline.tasks}
        assert task_dict.keys() == {stub_task.name, stub_task_2.name}
        assert task_dict[stub_task_2.name].depends_on[0].task_key == stub_task.name
        # TODO: increase coverage as implementation matures

    @pytest.mark.xfail
    @pytest.mark.slow
    def test_can_decompile_single_task(
        self,
        get_stub_task: Callable[..., task.Task],
        get_stub_pipeline: Callable[..., pipeline.Pipeline],
    ) -> None: ...

    @pytest.mark.xfail
    @pytest.mark.slow
    def test_can_decompile_multiple_tasks(
        self,
        get_stub_tasks: Callable[..., list[task.Task]],
        get_stub_pipeline: Callable[..., pipeline.Pipeline],
    ) -> None: ...
