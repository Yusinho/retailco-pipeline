{{
    config(materialized='table')
}}

with source as (
    select * from {{ ref('stg_stores') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['store_id']) }}  as store_key,
        store_id,
        store_name,
        city,
        state,
        region,
        created_at,
        updated_at
    from source
)

select * from final
