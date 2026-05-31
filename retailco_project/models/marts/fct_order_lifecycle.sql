{{
    config(materialized='table')
}}

-- Accumulating snapshot: one row per order.
-- Status timestamps fill in as the order progresses through its lifecycle.
-- pending → paid → shipped → delivered

with orders as (
    select * from {{ ref('stg_orders') }}
),

dim_customer as (
    select * from {{ ref('dim_customer') }}
    where is_current = true
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
        {{ dbt_utils.generate_surrogate_key(['o.order_id']) }} as lifecycle_key,

        -- Date FKs for each status milestone
        dd_order.date_key                           as order_date_key,
        dd_paid.date_key                            as paid_date_key,
        dd_shipped.date_key                         as shipped_date_key,
        dd_delivered.date_key                       as delivered_date_key,

        -- Dimension FKs
        dc.customer_key,
        ds.store_key,
        de.employee_key,

        -- Natural keys
        o.order_id,
        o.customer_id,
        o.store_id,
        o.employee_id,

        -- Status
        o.order_status,

        -- Status timestamps
        o.order_date,
        o.paid_at,
        o.shipped_at,
        o.delivered_at,

        -- Lag measures (days between stages)
        case when o.paid_at is not null
             then extract(epoch from (o.paid_at - o.order_date)) / 86400
             end                                    as days_to_payment,

        case when o.shipped_at is not null and o.paid_at is not null
             then extract(epoch from (o.shipped_at - o.paid_at)) / 86400
             end                                    as days_to_shipment,

        case when o.delivered_at is not null and o.shipped_at is not null
             then extract(epoch from (o.delivered_at - o.shipped_at)) / 86400
             end                                    as days_to_delivery,

        -- Flags
        case when o.order_status = 'delivered' then true else false end as is_completed,
        case when o.order_status = 'cancelled' then true else false end as is_cancelled,

        o.created_at,
        o.updated_at

    from orders o
    join dim_customer  dc       on o.customer_id  = dc.customer_id
    join dim_store     ds       on o.store_id     = ds.store_id
    join dim_employee  de       on o.employee_id  = de.employee_id
    join dim_date      dd_order on dd_order.full_date = o.order_date::date

    -- Left joins for optional milestone dates
    left join dim_date dd_paid      on dd_paid.full_date      = o.paid_at::date
    left join dim_date dd_shipped   on dd_shipped.full_date   = o.shipped_at::date
    left join dim_date dd_delivered on dd_delivered.full_date = o.delivered_at::date
)

select * from final
