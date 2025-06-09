import os
from collections.abc import Callable, Generator
from datetime import datetime
from pathlib import Path
from typing import Any

import pytest
from airflow import models
from airflow.models import dagbag

os.environ["PYTHONPATH"] = "./tests"
os.environ["AIRFLOW_VAR_ALGO_PROJECT"] = "nbcu-ds-algo-int-001"
os.environ["AIRFLOW_VAR_DS_BQ_DATA_ENV"] = "nbcu-ds-prod-001"
os.environ["AIRFLOW_VAR_CLUSTER_PROJECT"] = "unused"
os.environ["AIRFLOW_VAR_TAG"] = "unused"
os.environ["AIRFLOW_VAR_CLUSTER_NAME"] = "unused"
os.environ["AIRFLOW_VAR_CLUSTER_LOCATION"] = "unused"
os.environ["AIRFLOW_VAR_NAMESPACE"] = "unused"
os.environ["AIRFLOW_VAR_START_DATE"] = "unused"


@pytest.fixture(scope="function")
def test_dag() -> models.DAG:
    return models.DAG(
        dag_id="test", start_date=datetime.strptime("2023-02-10", "%Y-%m-%d")
    )


@pytest.fixture(scope="function")
def get_dag_from_string(
    tmp_path: Path,
) -> Generator[Callable[..., models.DAG], Any, None]:
    file_name: Path = tmp_path / "test_dag.py"
    dag_bags: list[dagbag.DagBag] = []

    def _get_dag_from_string(dag_id: str, dag_definition: str) -> models.DAG:
        cleaned_dag_definition = dag_definition.replace("| {{ dag_run.conf }}", "")
        with file_name.open(mode="w+") as dag_file:
            dag_file.write(cleaned_dag_definition)
            dag_file.flush()
            dag_bag: dagbag.DagBag = dagbag.DagBag(
                dag_folder=file_name.parent, include_examples=False
            )
            dag_bags.append(dag_bag)
            return dag_bag.dags[dag_id]

    yield _get_dag_from_string

    for dag_bag in dag_bags:
        del dag_bag
