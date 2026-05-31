with source as (
    select * from {{ source('raw', 'order_items') }}
),
renamed as (
    select
        "id"::text                as order_item_id,
        "orderId"::text           as order_id,
        "productId"::text         as product_id,
        "quantity"::integer       as quantity,
        "unitPrice"::numeric      as unit_price,
        "discountPct"::numeric    as discount_pct,
        "lineTotal"::numeric      as line_total,
        "createdAt"::timestamptz  as created_at,
        "updatedAt"::timestamptz  as updated_at
    from source
)
select * from renamed