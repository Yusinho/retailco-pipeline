with source as (
    select * from {{ source('raw', 'products') }}
),
renamed as (
    select
        "id"::text                as product_id,
        "name"::text              as product_name,
        "category"::text          as category,
        "subCategory"::text       as sub_category,
        "brand"::text             as brand,
        "supplier"::text          as supplier,
        "costPrice"::numeric      as cost_price,
        "sellingPrice"::numeric   as unit_price,
        "isDeleted"::boolean      as is_deleted,
        "createdAt"::timestamptz  as created_at,
        "updatedAt"::timestamptz  as updated_at
    from source
)
select * from renamed