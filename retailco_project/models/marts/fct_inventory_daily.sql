{{
    config(materialized='table')
}}

with movements as (
    select * from {{ ref('stg_inventory_movements') }}
),

dim_product as (
    select * from {{ ref('dim_product') }}
    where is_current = true
),

dim_store as (
    select * from {{ ref('dim_store') }}
),

dim_date as (
    select * from {{ ref('dim_date') }}
),

-- Aggregate movements to daily level per product x store
daily_movements as (
    select
        product_id,
        store_id,
        movement_date,
        sum(quantity_change)                                        as net_quantity_change,
        sum(case when quantity_change > 0 then quantity_change
                 else 0 end)                                        as units_received,
        sum(case when quantity_change < 0 then abs(quantity_change)
                 else 0 end)                                        as units_sold_or_removed
    from movements
    group by product_id, store_id, movement_date
),

-- Calculate running balance (closing stock per day)
with_running_balance as (
    select
        *,
        sum(net_quantity_change) over (
            partition by product_id, store_id
            order by movement_date
            rows between unbounded preceding and current row
        ) as closing_stock
    from daily_movements
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['dm.product_id', 'dm.store_id', 'dm.movement_date']) }} as inventory_key,

        -- Date FK
        dd.date_key                         as snapshot_date_key,

        -- Dimension FKs
        dp.product_key,
        ds.store_key,

        -- Natural keys
        dm.product_id,
        dm.store_id,
        dm.movement_date                    as snapshot_date,

        -- Measures
        dm.net_quantity_change,
        dm.units_received,
        dm.units_sold_or_removed,
        dm.closing_stock

    from with_running_balance dm
    join dim_product   dp on dm.product_id  = dp.product_id
    join dim_store     ds on dm.store_id    = ds.store_id
    join dim_date      dd on dd.full_date   = dm.movement_date
)

select * from final
