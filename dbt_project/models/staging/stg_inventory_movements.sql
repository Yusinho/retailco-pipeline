with source as (
    select * from {{ source('raw', 'inventory_movements') }}
),
renamed as (
    select
        movement_id::text           as movement_id,
        product_id::text            as product_id,
        store_id::text              as store_id,
        movement_type::text         as movement_type,
        quantity_change::integer    as quantity_change,
        movement_date::date         as movement_date,
        created_at::timestamptz     as created_at,
        updated_at::timestamptz     as updated_at
    from source
)
select * from renamed
