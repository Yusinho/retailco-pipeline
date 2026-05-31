{{
    config(materialized='table')
}}

with payments as (
    select * from {{ ref('stg_payments') }}
),

flagged as (
    select payment_id from {{ ref('flagged_payments') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

dim_payment_method as (
    select * from {{ ref('dim_payment_method') }}
),

dim_store as (
    select * from {{ ref('dim_store') }}
),

dim_date as (
    select * from {{ ref('dim_date') }}
),

clean_payments as (
    -- Exclude anomalous payments flagged by data quality checks
    select p.*
    from payments p
    left join flagged f on p.payment_id = f.payment_id
    where f.payment_id is null
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['cp.payment_id']) }} as payment_key,

        -- Date FK
        dd.date_key                         as payment_date_key,

        -- Dimension FKs
        dpm.payment_method_key,
        ds.store_key,

        -- Natural keys
        cp.payment_id,
        cp.order_id,
        cp.payment_method_id,
        o.store_id,

        -- Measures
        cp.amount_paid,
        -- Negative amounts are refunds (valid, handled as non-additive)
        case when cp.amount_paid < 0 then true else false end as is_refund,
        cp.payment_status,
        cp.payment_date

    from clean_payments   cp
    join orders            o   on cp.order_id           = o.order_id
    join dim_payment_method dpm on cp.payment_method_id = dpm.payment_method_id
    join dim_store         ds   on o.store_id           = ds.store_id
    join dim_date          dd   on dd.full_date         = cp.payment_date::date
)

select * from final
