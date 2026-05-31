{{
    config(materialized='table')
}}

with order_items as (
    select * from {{ ref('stg_order_items') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

dim_customer as (
    select * from {{ ref('dim_customer') }}
    where is_current = true
      and is_deleted  = false
),

dim_product as (
    select * from {{ ref('dim_product') }}
    where is_current = true
      and is_deleted  = false
),

dim_store as (
    select * from {{ ref('dim_store') }}
),

dim_employee as (
    select * from {{ ref('dim_employee') }}
),

dim_date as (
    select * from {{ ref('dim_date') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['oi.order_item_id']) }} as sales_key,

        -- Date FK
        dd.date_key                         as order_date_key,

        -- Dimension FKs (surrogate)
        dc.customer_key,
        dp.product_key,
        ds.store_key,
        de.employee_key,

        -- Natural keys kept for traceability
        oi.order_item_id,
        oi.order_id,
        oi.product_id,
        o.customer_id,
        o.store_id,
        o.employee_id,

        -- Measures
        oi.quantity,
        oi.unit_price,
        oi.discount_amount,
        oi.line_total,
        oi.line_total - coalesce(oi.discount_amount, 0) as net_revenue,

        -- Order status
        o.order_status,
        o.order_date

    from order_items oi
    join orders       o  on oi.order_id      = o.order_id
    join dim_customer dc on o.customer_id    = dc.customer_id
    join dim_product  dp on oi.product_id    = dp.product_id
    join dim_store    ds on o.store_id       = ds.store_id
    join dim_employee de on o.employee_id    = de.employee_id
    join dim_date     dd on dd.full_date     = o.order_date::date

    -- Exclude cancelled or deleted items
    where o.order_status != 'cancelled'
)

select * from final
