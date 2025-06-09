from dataclasses import asdict, dataclass

from databricks.sdk.service import compute, jobs

from pipelines import pipeline, port, task, trigger


@dataclass
class DatabricksDeploymentArgs:
    google_service_account: str
    environment: str
    whl_path: str
    package_name: str
    configuration_item: str
    max_workers: int = 2
    service_now_id: str = "7038691"
    data_compliance: str = "None"
    node_type_id: str = "n2d-highmem-8"
    policy_id: str | None = None


@dataclass
class RequiredTags:
    data_compliance: str
    environment: str
    snow_id: str
    application_name: str


class Databricks:
    def compile(
        self, object: object, deploy_args: DatabricksDeploymentArgs
    ) -> jobs.JobSettings:
        if isinstance(object, pipeline.Pipeline):
            return jobs.JobSettings(
                name=object.name,
                edit_mode=jobs.JobEditMode.UI_LOCKED,
                schedule=(
                    self._pipeline_trigger_to_databricks_schedule(
                        pipeline_trigger=object.trigger
                    )
                    if object.trigger
                    else None
                ),
                tasks=[
                    self._pipeline_task_to_databricks_task(
                        task=task,
                        deploy_args=deploy_args,
                    )
                    for task in object.tasks
                ],
            )

        else:
            raise NotImplementedError

    def decompile(self, artifact: jobs.Job, object: type) -> port.Port:
        raise NotImplementedError

    def _pipeline_task_to_databricks_task(
        self,
        task: task.Task,
        deploy_args: DatabricksDeploymentArgs,
    ) -> jobs.Task:
        depends_on: list[jobs.TaskDependency] = [
            jobs.TaskDependency(task_key=name) for name in task.depends_on
        ]
        cluster_spec = self._get_cluster_spec(deploy_args=deploy_args)

        return jobs.Task(
            task_key=task.name,
            depends_on=depends_on,
            libraries=[compute.Library(whl=deploy_args.whl_path)],
            python_wheel_task=jobs.PythonWheelTask(
                package_name=deploy_args.package_name,
                entry_point=task.src.stem,
            ),
            new_cluster=cluster_spec,
        )

    def _get_cluster_spec(self, deploy_args: DatabricksDeploymentArgs):
        autoscale = compute.AutoScale(
            min_workers=1,
            max_workers=deploy_args.max_workers,
        )
        gcp_attributes = compute.GcpAttributes(
            availability=compute.GcpAvailability.ON_DEMAND_GCP,
            google_service_account=deploy_args.google_service_account,
        )
        return compute.ClusterSpec(
            autoscale=autoscale,
            gcp_attributes=gcp_attributes,
            custom_tags=asdict(
                RequiredTags(
                    data_compliance=deploy_args.data_compliance,
                    environment=deploy_args.environment,
                    application_name=deploy_args.configuration_item,
                    snow_id=deploy_args.service_now_id,
                )
            ),
            data_security_mode=compute.DataSecurityMode.SINGLE_USER,
            node_type_id=deploy_args.node_type_id,
            policy_id=deploy_args.policy_id,
            runtime_engine=compute.RuntimeEngine.STANDARD,
        )

    def _pipeline_trigger_to_databricks_schedule(
        self, pipeline_trigger: trigger.Trigger
    ) -> jobs.CronSchedule:
        match pipeline_trigger:
            case trigger.CronTrigger():
                return jobs.CronSchedule(
                    quartz_cron_expression=trigger.standard_to_quartz(
                        pipeline_trigger.schedule
                    ),
                    timezone_id="UTC",
                )
            case _:
                raise NotImplementedError(
                    "Only cron triggers are supported for databricks compilation at this time."
                )
