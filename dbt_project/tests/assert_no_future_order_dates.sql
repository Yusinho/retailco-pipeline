-- Custom test: fct_order_lifecycle should not have order dates in the future
select
    lifecycle_key,
    order_id,
    order_date
from {{ ref('fct_order_lifecycle') }}
where order_date > current_timestamp
