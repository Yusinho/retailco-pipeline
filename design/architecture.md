# RetailCo Data Platform — Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          ORCHESTRATION LAYER                                │
│                        Apache Airflow 2.9  (port 8080)                      │
│                                                                             │
│  DAG: retailco_pipeline  [@daily]                                           │
│                                                                             │
│  [1] extract_erp  ──►  [2] load_to_warehouse  ──►  [3] dbt_snapshot        │
│                                                          │                  │
│                                               [4] dbt_staging               │
│                                                          │                  │
│                                               [5] dbt_marts                 │
│                                                          │                  │
│                                               [6] dbt_test                  │
└─────────────────────────────────────────────────────────────────────────────┘

         │ Task 1                     │ Task 2              │ Tasks 3-6
         ▼                            ▼                     ▼

┌─────────────────┐      ┌────────────────────┐   ┌─────────────────────────┐
│   SOURCE LAYER  │      │    LAKE (Raw)       │   │  WAREHOUSE (Analytics)  │
│                 │      │                     │   │                         │
│  ERP REST API   │      │  PostgreSQL 15      │   │  PostgreSQL 15          │
│  (Heroku)       │─────►│  Database: lake     │   │  Database: warehouse    │
│                 │ HTTP  │  Schema:   raw      │──►│                         │
│  9 Entities:    │  +    │                     │   │  Schemas:               │
│  customers      │  API  │  raw.customers      │   │  ├── raw        (dlt)   │
│  products       │  Key  │  raw.products       │   │  ├── staging    (dbt)   │
│  stores         │       │  raw.stores         │   │  ├── marts      (dbt)   │
│  employees      │       │  raw.employees      │   │  └── snapshots  (dbt)   │
│  orders         │       │  raw.orders         │   │                         │
│  order_items    │       │  raw.order_items    │   │  Dimensions:            │
│  payments       │       │  raw.payments       │   │  dim_date               │
│  inventory_mvmt │       │  raw.inv_movements  │   │  dim_customer  (SCD2)   │
│  payment_methods│       │  raw.pay_methods    │   │  dim_product   (SCD2)   │
│                 │       │  raw._watermarks    │   │  dim_store              │
└─────────────────┘       └────────────────────┘   │  dim_employee           │
                                                    │  dim_payment_method     │
                          ┌────────────────────┐   │                         │
                          │  EXTRACTION TOOL   │   │  Facts:                 │
                          │  Python 3.11       │   │  fct_sales              │
                          │  erp_extractor.py  │   │  fct_payments           │
                          │                    │   │  fct_inventory_daily    │
                          │  Features:         │   │  fct_order_lifecycle    │
                          │  ✓ Pagination      │   │                         │
                          │  ✓ Incremental     │   │  DQ Artifact:           │
                          │  ✓ 429 backoff     │   │  flagged_payments       │
                          │  ✓ 500 retry       │   │                         │
                          │  ✓ Idempotent      │   └─────────────────────────┘
                          └────────────────────┘
                                    │
                          ┌────────────────────┐
                          │   LOADING TOOL     │
                          │   dlt (latest)     │
                          │   Incremental mode │
                          │   lake → warehouse │
                          └────────────────────┘
```

## Container layout (Docker Compose)

| Container           | Image                    | Port  | Purpose                    |
|---------------------|--------------------------|-------|----------------------------|
| postgres-meta       | postgres:15              | -     | Airflow metadata DB        |
| postgres-lake       | postgres:15              | 5433  | Raw data lake              |
| postgres-warehouse  | postgres:15              | 5434  | Analytics warehouse        |
| airflow-webserver   | apache/airflow:2.9.3     | 8080  | DAG UI                     |
| airflow-scheduler   | apache/airflow:2.9.3     | -     | Task scheduling            |
| airflow-init        | apache/airflow:2.9.3     | -     | One-time DB migration      |
