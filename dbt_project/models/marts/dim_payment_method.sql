{{
    config(materialized='table')
}}

with source as (
    select * from {{ ref('stg_payment_methods') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['payment_method_id']) }} as payment_method_key,
        payment_method_id,
        method_name,
        method_type,
        is_active,
        created_at,
        updated_at
    from source
)

select * from final
