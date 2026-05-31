with source as (
    select * from {{ source('raw', 'orders') }}
),
renamed as (
    select
        order_id::text              as order_id,
        customer_id::text           as customer_id,
        store_id::text              as store_id,
        employee_id::text           as employee_id,
        order_status::text          as order_status,
        order_date::timestamptz     as order_date,
        paid_at::timestamptz        as paid_at,
        shipped_at::timestamptz     as shipped_at,
        delivered_at::timestamptz   as delivered_at,
        created_at::timestamptz     as created_at,
        updated_at::timestamptz     as updated_at
    from source
)
select * from renamed
