with source as (
    select * from {{ source('raw', 'stores') }}
),
renamed as (
    select
        "id"::text                as store_id,
        "name"::text              as store_name,
        "city"::text              as city,
        "state"::text             as state,
        "address"::text           as address,
        "phone"::text             as phone,
        "managerName"::text       as manager_name,
        "openedDate"::date        as opened_date,
        "createdAt"::timestamptz  as created_at,
        "updatedAt"::timestamptz  as updated_at
    from source
)
select * from renamed