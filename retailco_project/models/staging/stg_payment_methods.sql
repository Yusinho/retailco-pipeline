with source as (
    select * from {{ source('raw', 'payment_methods') }}
),
renamed as (
    select
        "id"::text                as payment_method_id,
        "name"::text              as method_name,
        "provider"::text          as provider,
        "isDigital"::boolean      as is_digital,
        "createdAt"::timestamptz  as created_at,
        "updatedAt"::timestamptz  as updated_at
    from source
)
select * from renamed