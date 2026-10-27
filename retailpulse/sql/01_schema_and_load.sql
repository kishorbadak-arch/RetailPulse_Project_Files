-- RetailPulse: Star schema (PostgreSQL). Run in psql or pgAdmin.
CREATE SCHEMA IF NOT EXISTS retail;
SET search_path TO retail;

CREATE TABLE dim_date (
  date_key INT PRIMARY KEY, full_date DATE NOT NULL, year INT, quarter INT,
  month_num INT, month_name VARCHAR(3), week_of_year INT, day_name VARCHAR(3), is_weekend INT);
CREATE TABLE dim_store (
  store_key INT PRIMARY KEY, store_name VARCHAR(50), city VARCHAR(50),
  state VARCHAR(50), region VARCHAR(20), store_type VARCHAR(20));
CREATE TABLE dim_product (
  product_key INT PRIMARY KEY, product_name VARCHAR(60), category VARCHAR(40),
  sku VARCHAR(20) UNIQUE, unit_price NUMERIC(10,2), unit_cost NUMERIC(10,2));
CREATE TABLE dim_customer (
  customer_key INT PRIMARY KEY, customer_name VARCHAR(60), gender VARCHAR(10),
  age_group VARCHAR(10), city VARCHAR(50), segment VARCHAR(20), signup_date DATE);
CREATE TABLE fact_sales (
  order_line_id INT PRIMARY KEY, order_id VARCHAR(15) NOT NULL,
  date_key INT REFERENCES dim_date(date_key),
  customer_key INT REFERENCES dim_customer(customer_key),
  product_key INT REFERENCES dim_product(product_key),
  store_key INT REFERENCES dim_store(store_key),
  quantity INT, unit_price NUMERIC(10,2), discount_pct INT,
  sales_amount NUMERIC(12,2), cost_amount NUMERIC(12,2),
  payment_mode VARCHAR(20), return_flag INT);

-- Load CSVs (change the path; in psql use \copy instead of COPY)
\copy dim_date     FROM 'data/dim_date.csv'     CSV HEADER
\copy dim_store    FROM 'data/dim_store.csv'    CSV HEADER
\copy dim_product  FROM 'data/dim_product.csv'  CSV HEADER
\copy dim_customer FROM 'data/dim_customer.csv' CSV HEADER
\copy fact_sales   FROM 'data/fact_sales.csv'   CSV HEADER

-- Indexes for join/filter performance
CREATE INDEX idx_fact_date     ON fact_sales(date_key);
CREATE INDEX idx_fact_customer ON fact_sales(customer_key);
CREATE INDEX idx_fact_product  ON fact_sales(product_key);
CREATE INDEX idx_fact_store    ON fact_sales(store_key);

-- Data quality checks (all should return 0 rows / 0)
SELECT COUNT(*) AS orphan_customers FROM fact_sales f LEFT JOIN dim_customer c USING(customer_key) WHERE c.customer_key IS NULL;
SELECT COUNT(*) AS negative_sales   FROM fact_sales WHERE sales_amount < 0;
SELECT COUNT(*) AS duplicate_lines  FROM (SELECT order_line_id FROM fact_sales GROUP BY 1 HAVING COUNT(*)>1) t;
