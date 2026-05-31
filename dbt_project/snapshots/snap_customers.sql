{% snapshot snap_customers %}

{{
    config(
        target_schema='snapshots',
        strategy='timestamp',
        unique_key='customer_id',
        updated_at='updated_at',
    )
}}

select * from {{ ref('stg_customers') }}

{% endsnapshot %}
