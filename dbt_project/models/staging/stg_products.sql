with source as (
    select * from {{ source('raw', 'products') }}
),
renamed as (
    select
        product_id::text                    as product_id,
        product_name::text                  as product_name,
        category::text                      as category,
        unit_price::numeric                 as unit_price,
        cost_price::numeric                 as cost_price,
        supplier::text                      as supplier,
        (is_deleted::text)::boolean         as is_deleted,
        created_at::timestamptz             as created_at,
        updated_at::timestamptz             as updated_at
    from source
)
select * from renamed
