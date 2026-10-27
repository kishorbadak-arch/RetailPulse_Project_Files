SET search_path TO retail;

-- Flat view Power BI can import directly (net of returns)
CREATE OR REPLACE VIEW vw_sales_detail AS
SELECT f.order_line_id, f.order_id, d.full_date, d.year, d.quarter, d.month_num, d.month_name,
       c.customer_key, c.segment, c.age_group, c.gender,
       p.product_name, p.category, s.store_name, s.city AS store_city, s.region,
       f.quantity, f.discount_pct, f.payment_mode, f.return_flag,
       f.sales_amount, f.cost_amount,
       f.sales_amount - f.cost_amount AS profit
FROM fact_sales f
JOIN dim_date d     ON d.date_key = f.date_key
JOIN dim_customer c ON c.customer_key = f.customer_key
JOIN dim_product p  ON p.product_key = f.product_key
JOIN dim_store s    ON s.store_key = f.store_key;

-- Customer RFM segmentation
CREATE OR REPLACE VIEW vw_customer_rfm AS
WITH base AS (
  SELECT customer_key,
         (DATE '2025-12-31' - MAX(full_date)) AS recency_days,
         COUNT(DISTINCT order_id) AS frequency,
         SUM(sales_amount) AS monetary
  FROM vw_sales_detail WHERE return_flag = 0 GROUP BY customer_key),
scored AS (
  SELECT *, NTILE(5) OVER (ORDER BY recency_days DESC) AS r,
            NTILE(5) OVER (ORDER BY frequency)         AS f,
            NTILE(5) OVER (ORDER BY monetary)          AS m
  FROM base)
SELECT *, CASE
  WHEN r>=4 AND f>=4 AND m>=4 THEN 'Champions'
  WHEN r>=3 AND f>=3 THEN 'Loyal'
  WHEN r>=4 AND f<=2 THEN 'New / Promising'
  WHEN r<=2 AND f>=3 THEN 'At Risk'
  WHEN r<=2 AND f<=2 THEN 'Lost'
  ELSE 'Needs Attention' END AS rfm_segment
FROM scored;
