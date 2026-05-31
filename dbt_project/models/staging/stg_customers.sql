with source as (
    select * from {{ source('raw', 'customers') }}
),
renamed as (
    select
        customer_id::text                   as customer_id,
        first_name::text                    as first_name,
        last_name::text                     as last_name,
        email::text                         as email,
        phone::text                         as phone,
        address::text                       as address,
        city::text                          as city,
        state::text                         as state,
        customer_segment::text              as customer_segment,
        (is_deleted::text)::boolean         as is_deleted,
        created_at::timestamptz             as created_at,
        updated_at::timestamptz             as updated_at
    from source
)
select * from renamed
