# RetailCo Data Platform

**Team D — Stage 8 Pipeline Task**
Nigerian retail chain data engineering platform built with Airflow, dlt, dbt, and PostgreSQL.

---

## What This Builds

```
ERP REST API  →  Lake (PostgreSQL)  →  Warehouse (PostgreSQL)
                                              ↓
                                    dbt dimensional models
                                    (Kimball: 6 dims, 4 facts)
```

---

## Prerequisites

- Docker Desktop installed and running
- At least 4GB RAM available for Docker
- Git

---

## Setup — Step by Step

### 1. Clone the repository
```bash
git clone <your-repo-url>
cd retailco
```

### 2. Start all containers
```bash
docker-compose up -d
```

This starts:
- `postgres-lake` on port 5433 (raw data lake)
- `postgres-warehouse` on port 5434 (analytics warehouse)
- `airflow-webserver` on port 8080 (DAG UI)
- `airflow-scheduler` (runs in background)

Wait about 60 seconds for Airflow to initialise.

### 3. Open Airflow UI
Go to http://localhost:8080
- Username: `admin`
- Password: `admin`

### 4. Enable and trigger the pipeline
- Find the DAG called `retailco_pipeline`
- Toggle it ON (the switch on the left)
- Click the ▶ Run button to trigger it manually, or wait for the daily schedule

---

## Running the Pipeline

### Manual full run
```bash
# Trigger from CLI
docker-compose exec airflow-webserver \
    airflow dags trigger retailco_pipeline
```

### Backfill a date range
```bash
docker-compose exec airflow-webserver \
    airflow dags backfill retailco_pipeline \
    --start-date 2024-01-01 \
    --end-date 2024-01-31
```

### Full refresh (re-extract everything from scratch)
```bash
# Set full_refresh=True in the extractor call temporarily
docker-compose exec airflow-webserver \
    airflow tasks test retailco_pipeline extract_erp 2024-01-01
```

---

## Querying the Warehouse

Connect to the warehouse database:
```bash
docker-compose exec postgres-warehouse \
    psql -U warehouse -d warehouse
```

Or use any SQL client (DBeaver, TablePlus, pgAdmin):
- Host: `localhost`
- Port: `5434`
- User: `warehouse`
- Password: `warehouse`
- Database: `warehouse`

### Key queries

**Revenue by store this month:**
```sql
SELECT ds.store_name, SUM(fs.net_revenue) AS revenue
FROM marts.fct_sales fs
JOIN marts.dim_store ds ON fs.store_key = ds.store_key
JOIN marts.dim_date  dd ON fs.order_date_key = dd.date_key
WHERE dd.year_month = TO_CHAR(NOW(), 'YYYY-MM')
GROUP BY ds.store_name
ORDER BY revenue DESC;
```

**Top 10 products by units sold:**
```sql
SELECT dp.product_name, dp.category, SUM(fs.quantity) AS units_sold
FROM marts.fct_sales fs
JOIN marts.dim_product dp ON fs.product_key = dp.product_key
GROUP BY dp.product_name, dp.category
ORDER BY units_sold DESC
LIMIT 10;
```

**Payment method breakdown:**
```sql
SELECT dpm.method_name, COUNT(*) AS transactions, SUM(fp.amount_paid) AS total
FROM marts.fct_payments fp
JOIN marts.dim_payment_method dpm ON fp.payment_method_key = dpm.payment_method_key
WHERE fp.is_refund = false
GROUP BY dpm.method_name
ORDER BY total DESC;
```

**Flagged anomalous payments:**
```sql
SELECT flag_reason, COUNT(*), SUM(amount_paid)
FROM marts.flagged_payments
GROUP BY flag_reason;
```

---

## Project Structure

```
retailco/
├── docker-compose.yml          # All containers
├── init/
│   ├── lake_init.sql           # Lake schema setup
│   └── warehouse_init.sql      # Warehouse schema setup
├── extractor/
│   └── erp_extractor.py        # Checkpoint 2: ERP → Lake
├── dlt_pipeline/
│   └── lake_to_warehouse.py    # Checkpoint 3: Lake → Warehouse
├── dbt_project/
│   ├── dbt_project.yml
│   ├── profiles.yml
│   ├── models/
│   │   ├── staging/            # One model per entity, type-cast + rename
│   │   └── marts/              # 6 dims + 4 facts + flagged_payments
│   ├── snapshots/              # SCD2 for customers + products
│   └── tests/                  # Custom data quality tests
├── airflow/
│   └── dags/
│       └── retailco_pipeline.py # Checkpoint 5: End-to-end DAG
├── design/
│   ├── bus_matrix.md           # Kimball bus matrix
│   ├── warehouse_erd.md        # All tables, PKs, FKs, SCD2 columns
│   └── architecture.md         # Full system architecture diagram
└── docs/
    └── business_insights.md    # 5 business questions answered with SQL
```

---

## Pipeline Task Order

```
extract_erp          # Python: ERP API → lake.raw.*
    ↓
load_to_warehouse    # dlt: lake.raw.* → warehouse.raw.*
    ↓
dbt_snapshot         # dbt snapshot: SCD2 for customers + products
    ↓
dbt_staging          # dbt run --select staging
    ↓
dbt_marts            # dbt run --select marts
    ↓
dbt_test             # dbt test: all schema + custom tests
```

Each task only starts when the previous one completes successfully.
Any failure stops all downstream tasks.
All tasks retry 2 times with exponential backoff before failing.

---

## API Key

The ERP API key is set as an environment variable in `docker-compose.yml`.
Do not commit it to git. For production, use Docker secrets or a vault.

Team: Team D
Team ID: b11c6102-05a3-4ca7-85f5-4acb157650e6

---

## Troubleshooting

**Airflow shows "heartbeat" errors on startup:**
Wait 60–90 seconds. The scheduler takes time to start on first run.

**dbt models fail with "relation does not exist":**
Make sure the extract and load tasks completed first.
Check `warehouse.raw` schema has data before running dbt.

**429 errors in extractor logs:**
Expected. The extractor handles these automatically with backoff.
If a task fails after 5 retries, the API was down — re-trigger the DAG.

**Containers not starting:**
```bash
docker-compose down -v  # remove volumes and try again
docker-compose up -d
```
