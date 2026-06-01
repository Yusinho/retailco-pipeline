# RetailCo Business Insights
## Answering the Five Management Questions

---

### 1. Revenue Performance

**Which stores, products, and categories are driving sales, and how does it trend over time?**

```sql
-- Revenue by store
SELECT
    ds.store_name,
    ds.city,
    dd.year_month,
    SUM(fs.net_revenue)   AS total_revenue,
    COUNT(fs.sales_key)   AS total_transactions
FROM marts.fct_sales fs
JOIN marts.dim_store ds ON fs.store_key = ds.store_key
JOIN marts.dim_date  dd ON fs.order_date_key = dd.date_key
WHERE fs.order_status != 'cancelled'
GROUP BY ds.store_name, ds.city, dd.year_month
ORDER BY dd.year_month DESC, total_revenue DESC;
```

```sql
-- Revenue by product category (top 10)
SELECT
    dp.category,
    SUM(fs.net_revenue)   AS total_revenue,
    SUM(fs.quantity)      AS units_sold,
    ROUND(AVG(fs.unit_price), 2) AS avg_selling_price
FROM marts.fct_sales fs
JOIN marts.dim_product dp ON fs.product_key = dp.product_key
GROUP BY dp.category
ORDER BY total_revenue DESC
LIMIT 10;
```

**Insight:** Kano leads in both total revenue and transaction count 

across the dataset. Lagos ranks second by transaction counts. Abuja shows the 
highest average order value per transaction. This challenges the 
assumption that population density alone drives retail revenue and 
suggests store-level factors: product mix, competition density and 
purchasing behaviour — may be stronger determinants of performance.

---

### 2. Customer Behaviour

**How often do customers purchase, what is their average order value, and how do segments differ?**

```sql
-- Customer purchase frequency and AOV by segment
SELECT
    dc.customer_segment,
    COUNT(DISTINCT fol.order_id)              AS total_orders,
    COUNT(DISTINCT fol.customer_key)          AS unique_customers,
    ROUND(COUNT(DISTINCT fol.order_id)::numeric
          / NULLIF(COUNT(DISTINCT fol.customer_key), 0), 2)  AS avg_orders_per_customer,
    ROUND(SUM(fs.net_revenue)
          / NULLIF(COUNT(DISTINCT fol.order_id), 0), 2)      AS avg_order_value
FROM marts.fct_order_lifecycle fol
JOIN marts.dim_customer dc ON fol.customer_key = dc.customer_key
JOIN marts.fct_sales    fs ON fol.order_id     = fs.order_id
WHERE dc.is_current = true
  AND fol.is_cancelled = false
GROUP BY dc.customer_segment
ORDER BY avg_order_value DESC;
```

**Insight:** Premium segments will show lower purchase frequency but higher average
order values. Mass-market segments show the reverse — high frequency, lower AOV.
Repeat purchase rate is the key metric: customers who have purchased 3 or more times
in a 90-day window are the highest-value cohort and should be the primary target for
loyalty programmes.

---

### 3. Product and Discount Analysis

**What sells, what gets discounted, and what is the margin impact?**

```sql
-- Discount rate and margin by product
SELECT
    dp.product_name,
    dp.category,
    SUM(fs.quantity)                                         AS units_sold,
    SUM(fs.discount_amount)                                  AS total_discount_given,
    SUM(fs.net_revenue)                                      AS net_revenue,
    ROUND(SUM(fs.discount_amount)
          / NULLIF(SUM(fs.line_total), 0) * 100, 2)         AS discount_rate_pct,
    ROUND((SUM(fs.net_revenue) - SUM(dp.cost_price * fs.quantity))
          / NULLIF(SUM(fs.net_revenue), 0) * 100, 2)        AS gross_margin_pct
FROM marts.fct_sales fs
JOIN marts.dim_product dp ON fs.product_key = dp.product_key
WHERE dp.is_current = true
GROUP BY dp.product_name, dp.category
HAVING SUM(fs.quantity) > 0
ORDER BY gross_margin_pct ASC;
```

**Insight:** High discount rates erode margin significantly on products that were
already low-margin. The most dangerous pattern is high discount rate + low margin —
those products are being sold at near-cost. Products with high margin and high
discount rate are candidates for discount policy tightening, as the business can
absorb it but is leaving money on the table unnecessarily.

---

### 4. Payment Channel Insights

**Which payment methods are used, and are there anomalies?**

```sql
-- Payment method breakdown
SELECT
    dpm.method_name,
    dpm.method_type,
    COUNT(fp.payment_key)                    AS transaction_count,
    SUM(CASE WHEN fp.is_refund THEN 1 ELSE 0 END) AS refund_count,
    SUM(fp.amount_paid)                      AS total_amount,
    ROUND(AVG(fp.amount_paid), 2)            AS avg_transaction_value
FROM marts.fct_payments fp
JOIN marts.dim_payment_method dpm ON fp.payment_method_key = dpm.payment_method_key
WHERE fp.is_refund = false
GROUP BY dpm.method_name, dpm.method_type
ORDER BY transaction_count DESC;
```

```sql
-- Anomaly check: flagged payments summary
SELECT
    flag_reason,
    COUNT(*)         AS count,
    SUM(amount_paid) AS total_amount
FROM marts.flagged_payments
GROUP BY flag_reason;
```

**Insight:** Mobile money (like Opay, Moniepoint, PalmPay) is expected to dominate
in Nigeria's retail environment, particularly in Lagos and Abuja. Card payments
will be stronger in upmarket stores. A high volume of zero-amount payments from a
single channel would indicate a POS integration bug rather than actual fraud — those
should be flagged for the technical team, not the fraud team.

---

### 5. Operational Data Quality

**What anomalies exist in the raw data, and how are they flagged?**

```sql
-- All flagged payments with context
SELECT
    fl.payment_id,
    fl.order_id,
    fl.amount_paid,
    fl.payment_status,
    fl.flag_reason,
    fl.payment_date
FROM marts.flagged_payments fl
ORDER BY fl.payment_date DESC;
```

```sql
-- Orders stuck in pending for more than 7 days
SELECT
    order_id,
    order_status,
    order_date,
    EXTRACT(EPOCH FROM (NOW() - order_date)) / 86400 AS days_since_order
FROM marts.fct_order_lifecycle
WHERE order_status = 'pending'
  AND order_date < NOW() - INTERVAL '7 days'
ORDER BY days_since_order DESC;
```

```sql
-- Products with no inventory movements in the last 30 days (dead stock risk)
SELECT
    dp.product_name,
    dp.category,
    ds.store_name,
    MAX(fi.snapshot_date) AS last_movement_date
FROM marts.fct_inventory_daily fi
JOIN marts.dim_product dp ON fi.product_key = dp.product_key
JOIN marts.dim_store   ds ON fi.store_key   = ds.store_key
GROUP BY dp.product_name, dp.category, ds.store_name
HAVING MAX(fi.snapshot_date) < CURRENT_DATE - 30
ORDER BY last_movement_date ASC;
```

**Insight:** The three most common data quality issues in retail pipelines are:
(1) zero-amount payments from POS system glitches,
(2) orders stuck in pending due to payment gateway timeouts, and
(3) inventory mismatches where physical counts diverge from system records.
All three are detectable from the warehouse and all three have named owners
who should receive weekly alerts from the BI layer.
