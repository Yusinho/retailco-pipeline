# RetailCo Kimball Bus Matrix

A bus matrix maps each business process (fact table) against the shared dimensions.
A ✓ means the dimension is used by that fact table.

|                         | dim_date | dim_customer | dim_product | dim_store | dim_employee | dim_payment_method |
|-------------------------|:--------:|:------------:|:-----------:|:---------:|:------------:|:------------------:|
| **fct_sales**           |    ✓     |      ✓       |      ✓      |     ✓     |      ✓       |                    |
| **fct_payments**        |    ✓     |              |             |     ✓     |              |         ✓          |
| **fct_inventory_daily** |    ✓     |              |      ✓      |     ✓     |              |                    |
| **fct_order_lifecycle** |    ✓     |      ✓       |             |     ✓     |      ✓       |                    |

---

## Grain Definitions

| Fact Table              | Grain                                     | Type                  |
|-------------------------|-------------------------------------------|-----------------------|
| fct_sales               | One row per order line item               | Transactional         |
| fct_payments            | One row per payment event                 | Transactional         |
| fct_inventory_daily     | One row per product × store × day        | Periodic Snapshot     |
| fct_order_lifecycle     | One row per order (status timestamps fill in) | Accumulating Snapshot |

---

## SCD Type 2 Dimensions

| Dimension     | Tracked Columns                          | Mechanism      |
|---------------|------------------------------------------|----------------|
| dim_customer  | segment, address, city, state            | dbt snapshot   |
| dim_product   | unit_price, cost_price, category         | dbt snapshot   |

All other dimensions are Type 1 (overwrite).

---

## Conformed Dimensions
All six dimensions are shared across fact tables — this is the definition of a conformed dimension in the Kimball framework. A query joining fct_sales and fct_payments on dim_store will produce consistent results because both fact tables use the same store_key from the same dim_store table.
