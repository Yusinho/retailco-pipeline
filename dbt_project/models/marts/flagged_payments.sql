{{
    config(materialized='table', schema='marts')
}}

-- Anomalous payments isolated here so they are excluded from fct_payments.
-- Anomalous = amount_paid = 0  OR  amount_paid < 0 that is NOT a refund
-- (refund records have payment_status = 'refund'; legitimate negatives are kept in fct_payments)

with payments as (
    select * from {{ ref('stg_payments') }}
)

select
    payment_id,
    order_id,
    payment_method_id,
    amount_paid,
    payment_date,
    payment_status,
    case
        when amount_paid = 0               then 'zero_amount'
        when amount_paid < 0
         and payment_status != 'refund'    then 'unexplained_negative'
        else 'other'
    end                                     as flag_reason,
    created_at,
    updated_at
from payments
where
    amount_paid = 0
    or (amount_paid < 0 and payment_status != 'refund')
