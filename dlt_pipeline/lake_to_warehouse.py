"""
RetailCo dlt Pipeline  –  Checkpoint 3
Reads from lake.raw.* and loads into warehouse.raw.*
Uses dlt incremental mode so only new/updated rows move.
"""

import os
import dlt
from dlt.sources.sql_database import sql_database
from dlt.common.configuration.specs import ConnectionStringCredentials

LAKE_DB      = os.environ["LAKE_DB_URL"]
WAREHOUSE_DB = os.environ["WAREHOUSE_DB_URL"]

ENTITIES = [
    "customers", "products", "stores", "employees",
    "orders", "order_items", "payments",
    "inventory_movements", "payment_methods",
]


@dlt.source
def lake_source():
    source = sql_database(
        credentials=ConnectionStringCredentials(LAKE_DB),
        schema="raw",
        table_names=ENTITIES,
        incremental=dlt.sources.incremental(
            cursor_path="_extracted_at",
        ),
        reflection_level="full_with_precision",
    )
    return source


def run_pipeline():
    pipeline = dlt.pipeline(
        pipeline_name="retailco_lake_to_warehouse",
        destination=dlt.destinations.postgres(WAREHOUSE_DB),
        dataset_name="raw",
        full_refresh=False,
    )
    load_info = pipeline.run(lake_source())
    print(load_info)
    return load_info


if __name__ == "__main__":
    run_pipeline()
