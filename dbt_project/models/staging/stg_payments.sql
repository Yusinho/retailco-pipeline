with source as (
    select * from {{ source('raw', 'payments') }}
),
renamed as (
    select
        payment_id::text            as payment_id,
        order_id::text              as order_id,
        payment_method_id::text     as payment_method_id,
        amount_paid::numeric        as amount_paid,
        payment_date::timestamptz   as payment_date,
        payment_status::text        as payment_status,
        created_at::timestamptz     as created_at,
        updated_at::timestamptz     as updated_at
    from source
)
select * from renamed
