# RetailCo Warehouse ERD

## Dimension Tables

### dim_date
| Column          | Type    | Key | Notes                        |
|-----------------|---------|-----|------------------------------|
| date_key        | INT     | PK  | YYYYMMDD integer             |
| full_date       | DATE    |     |                              |
| year            | INT     |     |                              |
| quarter         | INT     |     | 1–4                          |
| month           | INT     |     | 1–12                         |
| month_name      | TEXT    |     |                              |
| week_of_year    | INT     |     |                              |
| day_of_month    | INT     |     |                              |
| day_of_week     | INT     |     | 0=Sunday                     |
| day_name        | TEXT    |     |                              |
| is_weekend      | BOOLEAN |     |                              |
| is_public_holiday | BOOLEAN |  |  Nigeria public holidays     |
| year_quarter    | TEXT    |     | e.g. 2024-Q1                 |
| year_month      | TEXT    |     | e.g. 2024-01                 |

---

### dim_customer  (SCD Type 2)
| Column           | Type      | Key | Notes                        |
|------------------|-----------|-----|------------------------------|
| customer_key     | TEXT      | PK  | Surrogate key (MD5 hash)     |
| customer_id      | TEXT      | NK  | Natural key from ERP         |
| first_name       | TEXT      |     |                              |
| last_name        | TEXT      |     |                              |
| full_name        | TEXT      |     |                              |
| email            | TEXT      |     |                              |
| phone            | TEXT      |     |                              |
| address          | TEXT      |     | SCD2 tracked                 |
| city             | TEXT      |     | SCD2 tracked                 |
| state            | TEXT      |     | SCD2 tracked                 |
| customer_segment | TEXT      |     | SCD2 tracked                 |
| is_deleted       | BOOLEAN   |     | Soft delete flag             |
| valid_from       | TIMESTAMP |     | SCD2 effective start         |
| valid_to         | TIMESTAMP |     | SCD2 effective end (NULL=current) |
| is_current       | BOOLEAN   |     | TRUE for active version      |

---

### dim_product  (SCD Type 2)
| Column      | Type      | Key | Notes                        |
|-------------|-----------|-----|------------------------------|
| product_key | TEXT      | PK  | Surrogate key                |
| product_id  | TEXT      | NK  | Natural key from ERP         |
| product_name | TEXT     |     |                              |
| category    | TEXT      |     | SCD2 tracked                 |
| unit_price  | NUMERIC   |     | SCD2 tracked                 |
| cost_price  | NUMERIC   |     | SCD2 tracked                 |
| supplier    | TEXT      |     |                              |
| is_deleted  | BOOLEAN   |     | Soft delete flag             |
| valid_from  | TIMESTAMP |     |                              |
| valid_to    | TIMESTAMP |     |                              |
| is_current  | BOOLEAN   |     |                              |

---

### dim_store
| Column     | Type | Key | Notes        |
|------------|------|-----|--------------|
| store_key  | TEXT | PK  | Surrogate    |
| store_id   | TEXT | NK  |              |
| store_name | TEXT |     |              |
| city       | TEXT |     |              |
| state      | TEXT |     |              |
| region     | TEXT |     |              |

---

### dim_employee
| Column       | Type | Key | Notes        |
|--------------|------|-----|--------------|
| employee_key | TEXT | PK  | Surrogate    |
| employee_id  | TEXT | NK  |              |
| full_name    | TEXT |     |              |
| role         | TEXT |     |              |
| store_id     | TEXT | FK  | → dim_store  |
| hire_date    | DATE |     |              |

---

### dim_payment_method
| Column              | Type    | Key | Notes     |
|---------------------|---------|-----|-----------|
| payment_method_key  | TEXT    | PK  | Surrogate |
| payment_method_id   | TEXT    | NK  |           |
| method_name         | TEXT    |     |           |
| method_type         | TEXT    |     |           |
| is_active           | BOOLEAN |     |           |

---

## Fact Tables

### fct_sales  (Transactional — one row per order line)
| Column          | Type    | Key | Notes                     |
|-----------------|---------|-----|---------------------------|
| sales_key       | TEXT    | PK  | Surrogate                 |
| order_date_key  | INT     | FK  | → dim_date.date_key       |
| customer_key    | TEXT    | FK  | → dim_customer.customer_key |
| product_key     | TEXT    | FK  | → dim_product.product_key |
| store_key       | TEXT    | FK  | → dim_store.store_key     |
| employee_key    | TEXT    | FK  | → dim_employee.employee_key |
| order_item_id   | TEXT    | NK  |                           |
| order_id        | TEXT    |     |                           |
| quantity        | INT     |     | Additive measure          |
| unit_price      | NUMERIC |     | Semi-additive             |
| discount_amount | NUMERIC |     | Additive                  |
| line_total      | NUMERIC |     | Additive                  |
| net_revenue     | NUMERIC |     | Additive                  |
| order_status    | TEXT    |     |                           |

---

### fct_payments  (Transactional — one row per payment)
| Column              | Type    | Key | Notes                          |
|---------------------|---------|-----|--------------------------------|
| payment_key         | TEXT    | PK  | Surrogate                      |
| payment_date_key    | INT     | FK  | → dim_date.date_key            |
| payment_method_key  | TEXT    | FK  | → dim_payment_method           |
| store_key           | TEXT    | FK  | → dim_store.store_key          |
| payment_id          | TEXT    | NK  |                                |
| order_id            | TEXT    |     |                                |
| amount_paid         | NUMERIC |     | Negative = refund (non-additive) |
| is_refund           | BOOLEAN |     |                                |
| payment_status      | TEXT    |     |                                |
| payment_date        | TIMESTAMP |   |                                |

---

### fct_inventory_daily  (Periodic Snapshot — one row per product × store × day)
| Column              | Type    | Key | Notes                     |
|---------------------|---------|-----|---------------------------|
| inventory_key       | TEXT    | PK  | Surrogate                 |
| snapshot_date_key   | INT     | FK  | → dim_date.date_key       |
| product_key         | TEXT    | FK  | → dim_product.product_key |
| store_key           | TEXT    | FK  | → dim_store.store_key     |
| product_id          | TEXT    | NK  |                           |
| store_id            | TEXT    | NK  |                           |
| snapshot_date       | DATE    |     |                           |
| net_quantity_change | INT     |     | Additive                  |
| units_received      | INT     |     | Additive                  |
| units_sold_or_removed | INT   |     | Additive                  |
| closing_stock       | INT     |     | Semi-additive             |

---

### fct_order_lifecycle  (Accumulating Snapshot — one row per order)
| Column              | Type      | Key | Notes                     |
|---------------------|-----------|-----|---------------------------|
| lifecycle_key       | TEXT      | PK  | Surrogate                 |
| order_date_key      | INT       | FK  | → dim_date                |
| paid_date_key       | INT       | FK  | → dim_date (nullable)     |
| shipped_date_key    | INT       | FK  | → dim_date (nullable)     |
| delivered_date_key  | INT       | FK  | → dim_date (nullable)     |
| customer_key        | TEXT      | FK  | → dim_customer            |
| store_key           | TEXT      | FK  | → dim_store               |
| employee_key        | TEXT      | FK  | → dim_employee            |
| order_id            | TEXT      | NK  |                           |
| order_status        | TEXT      |     |                           |
| order_date          | TIMESTAMP |     |                           |
| paid_at             | TIMESTAMP |     | Fills in when paid        |
| shipped_at          | TIMESTAMP |     | Fills in when shipped     |
| delivered_at        | TIMESTAMP |     | Fills in when delivered   |
| days_to_payment     | NUMERIC   |     |                           |
| days_to_shipment    | NUMERIC   |     |                           |
| days_to_delivery    | NUMERIC   |     |                           |
| is_completed        | BOOLEAN   |     |                           |
| is_cancelled        | BOOLEAN   |     |                           |

---

## Data Quality Artifact (not in bus matrix)

### flagged_payments
| Column         | Type      | Notes                         |
|----------------|-----------|-------------------------------|
| payment_id     | TEXT      | PK                            |
| order_id       | TEXT      |                               |
| amount_paid    | NUMERIC   |                               |
| payment_status | TEXT      |                               |
| flag_reason    | TEXT      | zero_amount / unexplained_negative |
| payment_date   | TIMESTAMP |                               |
