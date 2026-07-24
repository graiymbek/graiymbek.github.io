-- ============================================================
-- Supply Chain Analytics — reference SQL
-- Mirrors the DAX measures used in the Power BI semantic model.
-- Schema assumed (ANSI SQL, adjust for your dialect):
--   fact_orders(order_id, order_item_id, customer_id, product_card_id,
--               order_date, shipping_date, days_shipping_real,
--               days_shipment_scheduled, delivery_status,
--               late_delivery_risk, shipping_mode, order_status,
--               market, order_region, order_country, order_item_quantity,
--               sales, order_profit_per_order)
--   dim_customer(customer_id, customer_segment, customer_city, customer_country)
--   dim_product(product_card_id, product_name, category_name, department_name)
-- ============================================================

-- Headline KPIs (Total Sales, Total Profit, Total Orders, Total Customers,
-- Avg Order Value, Profit Margin %) — matches the Executive Overview page.
SELECT
    SUM(sales)                                        AS total_sales,
    SUM(order_profit_per_order)                       AS total_profit,
    COUNT(DISTINCT order_id)                           AS total_orders,
    COUNT(DISTINCT customer_id)                         AS total_customers,
    SUM(sales) / NULLIF(COUNT(DISTINCT order_id), 0)    AS avg_order_value,
    SUM(order_profit_per_order) / NULLIF(SUM(sales), 0) AS profit_margin_pct
FROM fact_orders;

-- Monthly sales & profit trend
SELECT
    DATE_TRUNC('month', order_date)  AS order_month,
    SUM(sales)                       AS total_sales,
    SUM(order_profit_per_order)      AS total_profit,
    COUNT(DISTINCT order_id)         AS total_orders
FROM fact_orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY order_month;

-- Sales by market / department (Executive Overview bar charts)
SELECT market, SUM(sales) AS total_sales
FROM fact_orders
GROUP BY market
ORDER BY total_sales DESC;

SELECT p.department_name, SUM(f.sales) AS total_sales
FROM fact_orders f
JOIN dim_product p ON p.product_card_id = f.product_card_id
GROUP BY p.department_name
ORDER BY total_sales DESC;

-- Late delivery rate by shipping mode (Shipping & Fulfillment page)
SELECT
    shipping_mode,
    AVG(CASE WHEN late_delivery_risk = 1 THEN 1.0 ELSE 0 END) * 100 AS late_delivery_rate_pct,
    AVG(days_shipping_real)        AS avg_actual_days,
    AVG(days_shipment_scheduled)   AS avg_scheduled_days
FROM fact_orders
GROUP BY shipping_mode
ORDER BY late_delivery_rate_pct DESC;

-- Delivery status breakdown
SELECT
    delivery_status,
    COUNT(DISTINCT order_id) AS order_count,
    COUNT(DISTINCT order_id) * 100.0 / SUM(COUNT(DISTINCT order_id)) OVER () AS pct_of_orders
FROM fact_orders
GROUP BY delivery_status
ORDER BY order_count DESC;

-- Order status breakdown
SELECT order_status, COUNT(DISTINCT order_id) AS order_count
FROM fact_orders
GROUP BY order_status
ORDER BY order_count DESC;

-- Top 10 products / categories by sales (Products & Customers page)
SELECT p.product_name, SUM(f.sales) AS total_sales, SUM(f.order_profit_per_order) AS total_profit
FROM fact_orders f
JOIN dim_product p ON p.product_card_id = f.product_card_id
GROUP BY p.product_name
ORDER BY total_sales DESC
LIMIT 10;

SELECT p.category_name, SUM(f.sales) AS total_sales
FROM fact_orders f
JOIN dim_product p ON p.product_card_id = f.product_card_id
GROUP BY p.category_name
ORDER BY total_sales DESC
LIMIT 10;

-- Customer segment sales share
SELECT c.customer_segment, SUM(f.sales) AS total_sales, COUNT(DISTINCT f.customer_id) AS customers
FROM fact_orders f
JOIN dim_customer c ON c.customer_id = f.customer_id
GROUP BY c.customer_segment
ORDER BY total_sales DESC;

-- Repeat customer rate: share of customers with more than one order
WITH orders_per_customer AS (
    SELECT customer_id, COUNT(DISTINCT order_id) AS order_count
    FROM fact_orders
    GROUP BY customer_id
)
SELECT
    COUNT(*) FILTER (WHERE order_count > 1) * 100.0 / COUNT(*) AS repeat_customer_rate_pct
FROM orders_per_customer;
