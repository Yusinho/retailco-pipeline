with source as (
    select * from {{ source('raw', 'inventory_movements') }}
),
renamed as (
    select
        "id"::text                as movement_id,
        "productId"::text         as product_id,
        "storeId"::text           as store_id,
        "movementType"::text      as movement_type,
        "quantity"::integer       as quantity_change,
        "movedAt"::date           as movement_date,
        "notes"::text             as notes,
        "createdAt"::timestamptz  as created_at,
        "updatedAt"::timestamptz  as updated_at
    from source
)
select * from renamed