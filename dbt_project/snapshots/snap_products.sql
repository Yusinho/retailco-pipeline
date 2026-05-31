{% snapshot snap_products %}

{{
    config(
        target_schema='snapshots',
        strategy='timestamp',
        unique_key='product_id',
        updated_at='updated_at',
    )
}}

select * from {{ ref('stg_products') }}

{% endsnapshot %}
