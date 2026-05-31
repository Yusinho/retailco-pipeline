with source as (
    select * from {{ source('raw', 'employees') }}
),
renamed as (
    select
        employee_id::text       as employee_id,
        first_name::text        as first_name,
        last_name::text         as last_name,
        role::text              as role,
        store_id::text          as store_id,
        hire_date::date         as hire_date,
        created_at::timestamptz as created_at,
        updated_at::timestamptz as updated_at
    from source
)
select * from renamed
