{{
    config(materialized='table')
}}

with source as (
    select * from {{ ref('stg_employees') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['employee_id']) }} as employee_key,
        employee_id,
        first_name,
        last_name,
        first_name || ' ' || last_name                          as full_name,
        role,
        store_id,
        hire_date,
        created_at,
        updated_at
    from source
)

select * from final
