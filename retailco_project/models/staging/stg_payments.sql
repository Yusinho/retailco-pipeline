with source as (
    select * from {{ source('raw', 'payments') }}
),
renamed as (
    select
        "id"::text                as payment_id,
        "orderId"::text           as order_id,
        "customerId"::text        as customer_id,
        "paymentMethodId"::text   as payment_method_id,
        "amountPaid"::numeric     as amount_paid,
        "currency"::text          as currency,
        "status"::text            as payment_status,
        "paymentType"::text       as payment_type,
        "reference"::text         as reference,
        "paidAt"::timestamptz     as payment_date,
        "createdAt"::timestamptz  as created_at,
        "updatedAt"::timestamptz  as updated_at
    from source
)
select * from renamed