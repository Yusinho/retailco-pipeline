with source as (
    select * from {{ source('raw', 'orders') }}
),
renamed as (
    select
        "id"::text                    as order_id,
        "customerId"::text            as customer_id,
        "storeId"::text               as store_id,
        "employeeId"::text            as employee_id,
        "status"::text                as order_status,
        "totalAmount"::numeric        as total_amount,
        "discountAmount"::numeric     as discount_amount,
        "orderedAt"::timestamptz      as order_date,
        "paidAt"::timestamptz         as paid_at,
        "shippedAt"::timestamptz      as shipped_at,
        "deliveredAt"::timestamptz    as delivered_at,
        "cancelledAt"::timestamptz    as cancelled_at,
        "createdAt"::timestamptz      as created_at,
        "updatedAt"::timestamptz      as updated_at
    from source
)
select * from renamed