-- Requirement 5:  Inventory and Product Analytics
--  Objective: Analyze product performance and inventory turnover to inform stock management.

-- 1. Calculate the total number of unique products sold within the last year.
SELECT COUNT(DISTINCT product_id) AS TotalUniqueProducts
FROM Sales
WHERE order_date >= '2017-01-01'
  AND order_date <= '2017-12-31';


-- 2. Rank products by profit margin and identify the top 10 high-margin products.
WITH ProductProfitMargin AS (
    SELECT 
        product_id,
        product_name,
        SUM(profit) AS total_profit,
        SUM(total_sales) AS total_sales,
        (SUM(profit) / SUM(total_sales)) * 100 AS profit_margin
    FROM [dbo].[Sales]
    GROUP BY product_id, product_name
)
SELECT 
    product_id,
    product_name,
    total_profit,
    total_sales,
    round(profit_margin,2) as profit_margin,
    RANK() OVER (ORDER BY profit_margin DESC) AS profit_rank
FROM ProductProfitMargin
WHERE total_sales > 0  -- Avoid division by zero
ORDER BY profit_rank
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

--
WITH ProductProfitMargin AS (
    SELECT 
        product_id,
        product_name,
        SUM(profit) AS total_profit,
        SUM(total_sales) AS total_sales,
        (SUM(profit) / SUM(total_sales)) * 100 AS profit_margin
    FROM [dbo].[Sales]
    GROUP BY product_id, product_name
)
SELECT TOP 10
    product_id,
    product_name,
    total_profit,
    total_sales,
    profit_margin,
    RANK() OVER (ORDER BY profit_margin DESC) AS profit_rank
FROM ProductProfitMargin
WHERE total_sales > 0  -- Avoid division by zero
ORDER BY profit_margin DESC;


-- 3. Calculate product sales velocity by determining how many units of each product are sold per
 -- month.
 
WITH ProductSales AS (
    SELECT 
        product_id,
        product_name,
        SUM(quantity) AS total_quantity,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) + 1 AS total_months
    FROM [dbo].[Sales]
    GROUP BY product_id, product_name
)
SELECT 
    product_id,
    product_name,
    total_quantity,
    total_months,
    (total_quantity / total_months) AS sales_velocity_per_month
FROM ProductSales
WHERE total_months > 0  -- Ensure we don't divide by zero
ORDER BY sales_velocity_per_month DESC;


 --4. Identify which products have declining sales or have not been sold in the last 6 months.
 WITH SalesByPeriod AS (
    SELECT 
        product_id,
        product_name,
        SUM(CASE 
                WHEN order_date >= DATEADD(MONTH, -6, '2017-12-31') THEN quantity
                ELSE 0 
            END) AS recent_sales,  -- Sales in the last 6 months (up to 2017-12-31)
        SUM(CASE 
                WHEN order_date >= DATEADD(MONTH, -12, '2017-12-31') 
                     AND order_date < DATEADD(MONTH, -6, '2017-12-31') THEN quantity
                ELSE 0 
            END) AS previous_sales,  -- Sales in the 6-12 month period before 2017-12-31
        MAX(order_date) AS last_order_date
    FROM [dbo].[Sales]
    GROUP BY product_id, product_name
)
SELECT 
    product_id,
    product_name,
    recent_sales,
    previous_sales,
    last_order_date,
    CASE 
        WHEN recent_sales < previous_sales THEN 'Declining Sales'
        WHEN last_order_date < DATEADD(MONTH, -6, '2017-12-31') THEN 'No Sales in Last 6 Months'
        ELSE 'Stable or Growing'
    END AS status
FROM SalesByPeriod
WHERE recent_sales < previous_sales  -- Products with declining sales
   OR last_order_date < DATEADD(MONTH, -6, '2017-12-31')  -- Products with no sales in the last 6 months
ORDER BY status DESC, product_name;

 
-- 5. Create a report to identify inventory turnover for each product category and sub-category

WITH SalesData AS (
    SELECT
        category,
        sub_category,
        SUM(quantity) AS total_units_sold,
        DATEDIFF(MONTH, MIN(order_date), '2017-12-31') + 1 AS total_months
    FROM [dbo].[Sales]
    WHERE order_date <= '2017-12-31'  -- Ensure we only consider sales up to 2017-12-31
    GROUP BY category, sub_category
)
SELECT 
    category,
    sub_category,
    total_units_sold,
    total_months,
    (total_units_sold / total_months) AS inventory_turnover_per_month
FROM SalesData
WHERE total_months > 0  -- Ensure we have sales data to avoid division by zero
ORDER BY category, sub_category;
