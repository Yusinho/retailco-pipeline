-- Custom test: fct_sales should have no rows where net_revenue = 0
-- A zero revenue sale is either a data entry error or an ungifted item
-- that was not correctly categorised

select
    sales_key,
    order_id,
    net_revenue
from {{ ref('fct_sales') }}
where net_revenue = 0
