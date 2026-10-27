SET search_path TO retail;

-- Q1. Monthly revenue, profit and MoM growth (CTE + LAG)
WITH m AS (
  SELECT DATE_TRUNC('month', full_date)::date AS month,
         SUM(sales_amount) AS revenue, SUM(profit) AS profit
  FROM vw_sales_detail WHERE return_flag = 0 GROUP BY 1)
SELECT month, revenue, profit,
       ROUND(100.0*(revenue - LAG(revenue) OVER (ORDER BY month)) / NULLIF(LAG(revenue) OVER (ORDER BY month),0),1) AS mom_growth_pct
FROM m ORDER BY month;

-- Q2. Year-over-year revenue by quarter
SELECT year, quarter, SUM(sales_amount) AS revenue,
       ROUND(100.0*(SUM(sales_amount) - LAG(SUM(sales_amount)) OVER (PARTITION BY quarter ORDER BY year))
       / NULLIF(LAG(SUM(sales_amount)) OVER (PARTITION BY quarter ORDER BY year),0),1) AS yoy_pct
FROM vw_sales_detail WHERE return_flag = 0 GROUP BY year, quarter ORDER BY quarter, year;

-- Q3. Top 3 products per category by profit (DENSE_RANK)
SELECT * FROM (
  SELECT category, product_name, SUM(profit) AS profit,
         DENSE_RANK() OVER (PARTITION BY category ORDER BY SUM(profit) DESC) AS rnk
  FROM vw_sales_detail WHERE return_flag = 0 GROUP BY category, product_name) t
WHERE rnk <= 3 ORDER BY category, rnk;

-- Q4. Pareto / ABC analysis: products driving 80% of revenue
WITH p AS (
  SELECT product_name, SUM(sales_amount) AS revenue FROM vw_sales_detail WHERE return_flag=0 GROUP BY 1),
c AS (
  SELECT *, SUM(revenue) OVER (ORDER BY revenue DESC) / SUM(revenue) OVER () AS cum_share FROM p)
SELECT product_name, revenue, ROUND(100*cum_share,1) AS cum_share_pct,
       CASE WHEN cum_share <= .8 THEN 'A' WHEN cum_share <= .95 THEN 'B' ELSE 'C' END AS abc_class
FROM c ORDER BY revenue DESC;

-- Q5. Store performance: revenue, margin %, return rate, rank within region
SELECT region, store_name, SUM(sales_amount) AS revenue,
       ROUND(100.0*SUM(profit)/SUM(sales_amount),1) AS margin_pct,
       ROUND(100.0*AVG(return_flag),1) AS return_rate_pct,
       RANK() OVER (PARTITION BY region ORDER BY SUM(sales_amount) DESC) AS region_rank
FROM vw_sales_detail GROUP BY region, store_name ORDER BY region, region_rank;

-- Q6. Cohort retention: % of customers active N months after first purchase
WITH first_p AS (
  SELECT customer_key, DATE_TRUNC('month', MIN(full_date))::date AS cohort FROM vw_sales_detail GROUP BY 1),
act AS (
  SELECT DISTINCT s.customer_key, f.cohort,
         (EXTRACT(YEAR FROM AGE(DATE_TRUNC('month', s.full_date), f.cohort))*12
          + EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', s.full_date), f.cohort)))::int AS month_n
  FROM vw_sales_detail s JOIN first_p f USING(customer_key))
SELECT cohort, month_n, COUNT(*) AS active_customers,
       ROUND(100.0*COUNT(*)/FIRST_VALUE(COUNT(*)) OVER (PARTITION BY cohort ORDER BY month_n),1) AS retention_pct
FROM act WHERE month_n <= 6 GROUP BY cohort, month_n ORDER BY cohort, month_n;

-- Q7. RFM segment summary
SELECT rfm_segment, COUNT(*) AS customers, ROUND(SUM(monetary)) AS revenue,
       ROUND(100.0*SUM(monetary)/SUM(SUM(monetary)) OVER (),1) AS revenue_share_pct
FROM vw_customer_rfm GROUP BY rfm_segment ORDER BY revenue DESC;

-- Q8. Discount effectiveness: does deeper discount hurt margin?
SELECT discount_pct, COUNT(*) AS lines, ROUND(AVG(quantity),2) AS avg_qty,
       ROUND(100.0*SUM(profit)/SUM(sales_amount),1) AS margin_pct
FROM vw_sales_detail GROUP BY discount_pct ORDER BY discount_pct;

-- Q9. Running (cumulative) revenue per year
SELECT year, month_num, SUM(sales_amount) AS revenue,
       SUM(SUM(sales_amount)) OVER (PARTITION BY year ORDER BY month_num) AS ytd_revenue
FROM vw_sales_detail WHERE return_flag=0 GROUP BY year, month_num ORDER BY year, month_num;

-- Q10. Products frequently bought together (self-join)
SELECT a.product_name AS product_a, b.product_name AS product_b, COUNT(*) AS times_together
FROM vw_sales_detail a JOIN vw_sales_detail b
  ON a.order_id = b.order_id AND a.product_name < b.product_name
GROUP BY 1,2 ORDER BY times_together DESC LIMIT 10;
