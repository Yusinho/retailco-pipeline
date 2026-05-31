with source as (
    select * from {{ source('raw', 'stores') }}
),
renamed as (
    select
        store_id::text          as store_id,
        store_name::text        as store_name,
        city::text              as city,
        state::text             as state,
        region::text            as region,
        created_at::timestamptz as created_at,
        updated_at::timestamptz as updated_at
    from source
)
select * from renamed
