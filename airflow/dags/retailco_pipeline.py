"""
RetailCo Data Pipeline  –  Checkpoint 5
End-to-end daily DAG:
  Extract → Load (dlt) → dbt snapshot → dbt staging → dbt marts → dbt test

Schedule: @daily
Backfill: supported via catchup=True
Retries:  all tasks retry 2x with exponential backoff
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator

# ── Default args ──────────────────────────────────────────────────────────────
default_args = {
    "owner":             "retailco",
    "depends_on_past":   False,
    "start_date":        datetime(2024, 1, 1),
    "email_on_failure":  False,
    "retries":           2,
    "retry_delay":       timedelta(minutes=5),
    "retry_exponential_backoff": True,
    "max_retry_delay":   timedelta(minutes=30),
}

DBT_DIR = "/opt/airflow/dbt_project"
DBT_CMD = f"cd {DBT_DIR} && dbt"


# ── Python callables ──────────────────────────────────────────────────────────

def run_extractor(**context):
    """Run the ERP extractor for all nine entities."""
    import sys
    sys.path.insert(0, "/opt/airflow/extractor")
    from erp_extractor import run_all
    run_all(full_refresh=False)


def run_dlt_pipeline(**context):
    """Run the dlt lake-to-warehouse pipeline."""
    import sys
    sys.path.insert(0, "/opt/airflow/dlt_pipeline")
    from lake_to_warehouse import run_pipeline
    run_pipeline()


# ── DAG ───────────────────────────────────────────────────────────────────────
with DAG(
    dag_id="retailco_pipeline",
    default_args=default_args,
    description="RetailCo ERP → Lake → Warehouse → dbt",
    schedule_interval="@daily",
    catchup=True,
    max_active_runs=1,
    tags=["retailco", "pipeline"],
) as dag:

    # ── Task 1: Extract from ERP API → lake.raw.* ─────────────────────────────
    extract = PythonOperator(
        task_id="extract_erp",
        python_callable=run_extractor,
    )

    # ── Task 2: Load lake.raw.* → warehouse.raw.* via dlt ────────────────────
    load = PythonOperator(
        task_id="load_to_warehouse",
        python_callable=run_dlt_pipeline,
    )

    # ── Task 3: dbt snapshot (SCD2 for customers + products) ─────────────────
    dbt_snapshot = BashOperator(
        task_id="dbt_snapshot",
        bash_command=f"{DBT_CMD} snapshot --profiles-dir {DBT_DIR}",
    )

    # ── Task 4: dbt staging models ────────────────────────────────────────────
    dbt_staging = BashOperator(
        task_id="dbt_staging",
        bash_command=(
            f"{DBT_CMD} run "
            f"--select staging "
            f"--profiles-dir {DBT_DIR}"
        ),
    )

    # ── Task 5: dbt mart models (dims + facts) ────────────────────────────────
    dbt_marts = BashOperator(
        task_id="dbt_marts",
        bash_command=(
            f"{DBT_CMD} run "
            f"--select marts "
            f"--profiles-dir {DBT_DIR}"
        ),
    )

    # ── Task 6: dbt tests ─────────────────────────────────────────────────────
    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=f"{DBT_CMD} test --profiles-dir {DBT_DIR}",
    )

    # ── Dependency chain ──────────────────────────────────────────────────────
    # Each task only runs after the previous one completes successfully.
    # A failure at any stage stops everything downstream.
    extract >> load >> dbt_snapshot >> dbt_staging >> dbt_marts >> dbt_test
