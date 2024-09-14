-- Project 3: Sales Performance Dashboard
-- Objective: Build a SQL-driven sales dashboard that tracks key performance indicators (KPIs).
-- 1. Show total sales, profit, and quantity sold for the current month compared to the previous month.
WITH MaxOrderDate AS (
    -- Get the maximum order_date from the data
    SELECT MAX(order_date) AS max_order_date
    FROM DMSales
),
SalesData AS (
    -- Aggregate sales, profit, and quantity for both the current and previous months
    SELECT 
        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,
        SUM(CAST(total_sales AS DECIMAL(18,2))) AS total_sales,
        SUM(CAST(profit AS DECIMAL(18,2))) AS total_profit,
        SUM(quantity) AS total_quantity,
        (SELECT max_order_date FROM MaxOrderDate) AS max_order_date
    FROM DMSales
    WHERE order_date >= DATEADD(MONTH, -1, CAST(DATEADD(DAY, 1, EOMONTH((SELECT max_order_date FROM MaxOrderDate), -2)) AS DATE))
      AND order_date <= (SELECT max_order_date FROM MaxOrderDate)
    GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT 
    CASE 
        WHEN order_month = MONTH(max_order_date) AND order_year = YEAR(max_order_date) THEN 'Current Month'
        WHEN order_month = MONTH(DATEADD(MONTH, -1, max_order_date)) AND order_year = YEAR(DATEADD(MONTH, -1, max_order_date)) THEN 'Previous Month'
    END AS period,
    total_sales,
    total_profit,
    total_quantity
FROM SalesData
WHERE order_month IN (MONTH(max_order_date), MONTH(DATEADD(MONTH, -1, max_order_date)))
ORDER BY order_year, order_month DESC;


-- 2. Display a breakdown of sales by region and market segment.

SELECT 
    region,
    market_segment,
    SUM(CAST(total_sales AS DECIMAL(18,2))) AS total_sales,
    SUM(CAST(profit AS DECIMAL(18,2))) AS total_profit,
    SUM(quantity) AS total_quantity
FROM DMSales
GROUP BY region, market_segment
ORDER BY region, market_segment;


-- 3. Create KPIs for average order value (AOV), customer lifetime value (CLV), and profit margin.

WITH CustomerSales AS (
    -- Calculate total sales and total profit per customer
    SELECT 
        customer_id,
        customer_name,
        SUM(CAST(total_sales AS DECIMAL(18,2))) AS total_sales,
        SUM(CAST(profit AS DECIMAL(18,2))) AS total_profit,
        COUNT(DISTINCT order_id) AS total_orders
    FROM DMSales
    GROUP BY customer_id, customer_name
)
SELECT 
    -- Average Order Value (AOV): Total sales divided by total orders
    SUM(CAST(total_sales AS DECIMAL(18,2))) / SUM(total_orders) AS AOV,

    -- Customer Lifetime Value (CLV): Total sales per customer
    AVG(total_sales) AS CLV,

    -- Profit Margin: Total profit divided by total sales, expressed as a percentage
    (SUM(CAST(total_profit AS DECIMAL(18,2))) / SUM(CAST(total_sales AS DECIMAL(18,2)))) * 100 AS profit_margin
FROM CustomerSales;

-- 4. Hint: Use a CTE to track sales growth or decline month-over-month and year-over-year.

WITH MonthlySales AS (
    -- Calculate total sales for each year and month
    SELECT 
        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,
        SUM(CAST(total_sales AS DECIMAL(18,2))) AS total_sales
    FROM DMSales
    GROUP BY YEAR(order_date), MONTH(order_date)
),
SalesGrowth AS (
    -- Calculate Month-over-Month (MoM) and Year-over-Year (YoY) growth
    SELECT 
        order_year,
        order_month,
        total_sales,
        
        -- Calculate Month-over-Month (MoM) growth
        LAG(total_sales, 1) OVER (ORDER BY order_year, order_month) AS previous_month_sales,
        ((total_sales - LAG(total_sales, 1) OVER (ORDER BY order_year, order_month)) 
          / NULLIF(LAG(total_sales, 1) OVER (ORDER BY order_year, order_month), 0)) * 100 AS MoM_growth,

        -- Calculate Year-over-Year (YoY) growth
        LAG(total_sales, 12) OVER (ORDER BY order_year, order_month) AS previous_year_sales,
        ((total_sales - LAG(total_sales, 12) OVER (ORDER BY order_year, order_month)) 
          / NULLIF(LAG(total_sales, 12) OVER (ORDER BY order_year, order_month), 0)) * 100 AS YoY_growth
    FROM MonthlySales
)
SELECT 
    order_year,
    order_month,
    total_sales,
    MoM_growth,
    YoY_growth
FROM SalesGrowth
ORDER BY order_year, order_month;

-- 5. Provide a visual report of sales trends over time using date-based aggregations.

SELECT 
    CAST(YEAR(order_date) AS VARCHAR(4)) + '-' + RIGHT('00' + CAST(MONTH(order_date) AS VARCHAR(2)), 2) AS year_month,
    SUM(CAST(total_sales AS DECIMAL(18,2))) AS total_sales
FROM DMSales
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date);
