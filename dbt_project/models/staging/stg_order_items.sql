with source as (
    select * from {{ source('raw', 'order_items') }}
),
renamed as (
    select
        order_item_id::text     as order_item_id,
        order_id::text          as order_id,
        product_id::text        as product_id,
        quantity::integer       as quantity,
        unit_price::numeric     as unit_price,
        discount_amount::numeric as discount_amount,
        line_total::numeric     as line_total,
        created_at::timestamptz as created_at,
        updated_at::timestamptz as updated_at
    from source
)
select * from renamed
