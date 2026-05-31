with source as (
    select * from {{ source('raw', 'payment_methods') }}
),
renamed as (
    select
        payment_method_id::text     as payment_method_id,
        method_name::text           as method_name,
        method_type::text           as method_type,
        is_active::boolean          as is_active,
        created_at::timestamptz     as created_at,
        updated_at::timestamptz     as updated_at
    from source
)
select * from renamed
