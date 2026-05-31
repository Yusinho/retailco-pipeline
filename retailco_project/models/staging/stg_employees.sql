with source as (
    select * from {{ source('raw', 'employees') }}
),
renamed as (
    select
        "id"::text                as employee_id,
        "storeId"::text           as store_id,
        "firstName"::text         as first_name,
        "lastName"::text          as last_name,
        "email"::text             as email,
        "role"::text              as role,
        "hiredDate"::date         as hire_date,
        "isDeleted"::boolean      as is_deleted,
        "createdAt"::timestamptz  as created_at,
        "updatedAt"::timestamptz  as updated_at
    from source
)
select * from renamed