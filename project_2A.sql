USE furniture_store
GO

--  Furniture Store Sales
-- Project 2: Customer Segmentation
-- Objective: Identify customer segments to target for future marketing efforts.

-- R2-1: Create customer profiles by summarizing total sales and profit per customer
SELECT 
	customer_id,
	customer_name,
	round(sum(total_sales),2) as customer_sales,
	round(sum(profit),2) customer_profit
FROM DMSales
GROUP BY customer_id,customer_name
ORDER BY customer_profit DESC;

-- R2-2: Group customers by market segment and provide the total number of customers, average sales
SELECT 
    market_segment, 
    COUNT(DISTINCT customer_id) AS total_customers,
    AVG(CAST(total_sales AS DECIMAL(10, 2))) AS average_sales_per_customer,
    SUM(CAST(profit AS DECIMAL(10, 2))) AS total_profit
FROM 
    DMSales
GROUP BY 
    market_segment;

-- R2-3: Identify the top 10 customers by total sales and their respective regions.
SELECT top 10 region,customer_name,
sum(CAST(total_sales AS DECIMAL(10, 2))) as total_sales
FROM DMSales
GROUP BY customer_name,region
ORDER BY total_sales desc;

-- R-4: Hint: Use a CTE to identify the most popular products in each market segment.

WITH RankedProducts AS (
    SELECT 
        market_segment, 
        product_name, 
        SUM(quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY market_segment ORDER BY SUM(quantity) DESC) AS product_rank
    FROM 
        DMSales
    GROUP BY 
        market_segment, product_name
)
SELECT 
    market_segment, 
    product_name, 
    total_quantity
FROM 
    RankedProducts
WHERE 
    product_rank = 1
ORDER BY 
    market_segment;

-- R2-4 Analyze customer purchasing frequency (e.g., customers who have made more than 3
-- purchases).
SELECT
	customer_id,customer_name,
	count(*)  as order_count,
	count(order_id) as purchase_count
FROM DMSales
	GROUP BY customer_id,customer_name
	HAVING count(*) >3
	ORDER BY count(*) desc;