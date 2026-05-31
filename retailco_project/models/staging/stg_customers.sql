with source as (
    select * from {{ source('raw', 'customers') }}
),
renamed as (
    select
        "id"::text                as customer_id,
        "firstName"::text         as first_name,
        "lastName"::text          as last_name,
        "email"::text             as email,
        "phone"::text             as phone,
        "segment"::text           as customer_segment,
        "tier"::text              as tier,
        "address"::text           as address,
        "city"::text              as city,
        "state"::text             as state,
        "isDeleted"::boolean      as is_deleted,
        "createdAt"::timestamptz  as created_at,
        "updatedAt"::timestamptz  as updated_at
    from source
)
select * from renamed