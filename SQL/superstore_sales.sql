SELECT DATABASE(), @@hostname, @@port, CURRENT_USER();

SELECT COUNT(*) AS total_rows
FROM retail_sales_analysis.superstore_raw_import;
USE retail_sales_analysis;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT `Order ID`) AS unique_orders,
    SUM(`Sales` IS NULL OR TRIM(`Sales`) = '') AS missing_sales,
    SUM(`Profit` IS NULL OR TRIM(`Profit`) = '') AS missing_profit
FROM superstore_raw_import;
USE retail_sales_analysis;

DROP TABLE IF EXISTS superstore_sales;

CREATE TABLE superstore_sales AS
SELECT
    TRIM(`Order ID`) AS `Order ID`,
    STR_TO_DATE(TRIM(`Order Date`), '%d-%m-%Y') AS `Order Date`,
    STR_TO_DATE(TRIM(`Ship Date`), '%d-%m-%Y') AS `Ship Date`,
    TRIM(`Ship Mode`) AS `Ship Mode`,
    TRIM(`Customer ID`) AS `Customer ID`,
    TRIM(`Customer Name`) AS `Customer Name`,
    TRIM(`Segment`) AS `Segment`,
    TRIM(`Country`) AS `Country`,
    TRIM(`City`) AS `City`,
    TRIM(`State`) AS `State`,
    CAST(NULLIF(TRIM(`Postal Code`), '') AS UNSIGNED) AS `Postal Code`,
    TRIM(`Region`) AS `Region`,
    TRIM(`Product ID`) AS `Product ID`,
    TRIM(`Category`) AS `Category`,
    TRIM(`Sub-Category`) AS `Sub-Category`,
    TRIM(`Product Name`) AS `Product Name`,
    CAST(NULLIF(TRIM(`Sales`), '') AS DECIMAL(12,2)) AS `Sales`,
    CAST(NULLIF(TRIM(`Quantity`), '') AS UNSIGNED) AS `Quantity`,
    CAST(NULLIF(TRIM(`Discount`), '') AS DECIMAL(6,4)) AS `Discount`,
    CAST(NULLIF(TRIM(`Profit`), '') AS DECIMAL(12,2)) AS `Profit`,
    CAST(NULLIF(TRIM(`Year`), '') AS UNSIGNED) AS `Year`,
    TRIM(`Month`) AS `Month`,
    CAST(NULLIF(TRIM(`Month_number`), '') AS UNSIGNED) AS `Month_number`,
    CAST(NULLIF(TRIM(`PROFIT_MARGIN`), '') AS DECIMAL(10,4)) AS `PROFIT_MARGIN`,
    TRIM(`Profit_Status`) AS `Profit_Status`,
    CAST(NULLIF(TRIM(`shipping_days`), '') AS UNSIGNED) AS `shipping_days`
FROM superstore_raw_import;
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT `Order ID`) AS unique_orders,
    MIN(`Order Date`) AS first_order_date,
    MAX(`Order Date`) AS last_order_date,
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Profit`), 2) AS total_profit
FROM superstore_sales;
USE retail_sales_analysis;
-- overall business performance
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT `Order ID`) AS total_orders,
    COUNT(DISTINCT `Customer ID`) AS total_customers,
    COUNT(DISTINCT `Product ID`) AS unique_products,
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Profit`), 2) AS total_profit,
    ROUND(SUM(`Profit`) / NULLIF(SUM(`Sales`), 0) * 100, 2)
        AS profit_margin_pct,
    SUM(`Quantity`) AS units_sold
FROM superstore_sales;
-- Sales and profit by category
SELECT
    `Category`,
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Profit`), 2) AS total_profit,
    ROUND(
        SUM(`Profit`) / NULLIF(SUM(`Sales`), 0) * 100, 2
    ) AS profit_margin_pct
FROM superstore_sales
GROUP BY `Category`
ORDER BY total_sales DESC;
-- Monthly sales trend
SELECT
    `Year`,
    `Month_number`,
    `Month`,
    ROUND(SUM(`Sales`), 2) AS monthly_sales,
    ROUND(SUM(`Profit`), 2) AS monthly_profit
FROM superstore_sales
GROUP BY `Year`, `Month_number`, `Month`
ORDER BY `Year`, `Month_number`;
-- Regional sales and profit analysis
USE retail_sales_analysis;

SELECT
    `Region`,
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Profit`), 2) AS total_profit,
    ROUND(
        SUM(`Profit`) / NULLIF(SUM(`Sales`), 0) * 100,
        2
    ) AS profit_margin_pct,
    COUNT(DISTINCT `Order ID`) AS total_orders
FROM superstore_sales
GROUP BY `Region`
ORDER BY total_sales DESC;
-- Top 10 products by sales
SELECT
    `Product Name`,
    `Category`,
    `Sub-Category`,
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Profit`), 2) AS total_profit
FROM superstore_sales
GROUP BY `Product Name`, `Category`, `Sub-Category`
ORDER BY total_sales DESC
LIMIT 10;
-- Identify loss-making products
USE retail_sales_analysis;

SELECT
    `Product Name`,
    `Category`,
    `Sub-Category`,
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Profit`), 2) AS total_profit,
    ROUND(AVG(`Discount`) * 100, 2) AS avg_discount_pct
FROM superstore_sales
GROUP BY
    `Product Name`,
    `Category`,
    `Sub-Category`
HAVING SUM(`Profit`) < 0
ORDER BY total_profit ASC
LIMIT 10;
-- Top 10 most profitable products
SELECT
    `Product Name`,
    `Category`,
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Profit`), 2) AS total_profit
FROM superstore_sales
GROUP BY `Product Name`, `Category`
ORDER BY total_profit DESC
LIMIT 10;
-- Discount impact on profitability
SELECT
    CASE
        WHEN `Discount` = 0 THEN 'No Discount'
        WHEN `Discount` <= 0.10 THEN '1-10%'
        WHEN `Discount` <= 0.20 THEN '11-20%'
        WHEN `Discount` <= 0.30 THEN '21-30%'
        ELSE 'Above 30%'
    END AS discount_band,
    COUNT(*) AS transaction_lines,
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Profit`), 2) AS total_profit,
    ROUND(AVG(`Profit`), 2) AS avg_profit_per_line
FROM superstore_sales
GROUP BY discount_band
ORDER BY MIN(`Discount`);
-- Customer behaviour analysis
USE retail_sales_analysis;

SELECT
    `Customer ID`,
    `Customer Name`,
    COUNT(DISTINCT `Order ID`) AS total_orders,
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Profit`), 2) AS total_profit
FROM superstore_sales
GROUP BY `Customer ID`, `Customer Name`
ORDER BY total_sales DESC
LIMIT 10;
-- Repeat customer analysis
WITH customer_orders AS (
    SELECT
        `Customer ID`,
        COUNT(DISTINCT `Order ID`) AS order_count,
        SUM(`Sales`) AS total_sales
    FROM superstore_sales
    GROUP BY `Customer ID`
)
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,
    COUNT(*) AS number_of_customers,
    ROUND(SUM(total_sales), 2) AS total_sales,
    ROUND(AVG(total_sales), 2) AS avg_sales_per_customer
FROM customer_orders
GROUP BY customer_type;
-- Monthly sales growth using LAG() and CTE
USE retail_sales_analysis;

WITH monthly_sales AS (
    SELECT
        `Year`,
        `Month_number`,
        `Month`,
        SUM(`Sales`) AS total_sales,
        SUM(`Profit`) AS total_profit
    FROM superstore_sales
    GROUP BY `Year`, `Month_number`, `Month`
),
sales_comparison AS (
    SELECT
        `Year`,
        `Month_number`,
        `Month`,
        total_sales,
        total_profit,
        LAG(total_sales) OVER (
            ORDER BY `Year`, `Month_number`
        ) AS previous_month_sales
    FROM monthly_sales
)
SELECT
    `Year`,
    `Month`,
    ROUND(total_sales, 2) AS total_sales,
    ROUND(previous_month_sales, 2) AS previous_month_sales,
    ROUND(total_sales - previous_month_sales, 2) AS sales_change,
    ROUND(
        (total_sales - previous_month_sales)
        / NULLIF(previous_month_sales, 0) * 100,
        2
    ) AS growth_pct,
    ROUND(total_profit, 2) AS total_profit
FROM sales_comparison
ORDER BY `Year`, `Month_number`;
