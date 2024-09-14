USE furniture_store
GO

-- Problem 2: Customer Segmentation
-- Objective: Identify customer segments 
-- to target for future marketing efforts.
-- R1: Create customer profiles by summarizing 
-- total sales and profit per customer.
SELECT 
    customer_id,
    customer_name,
    SUM(CAST(total_sales AS FLOAT)) AS total_sales,
    SUM(CAST(profit AS FLOAT)) AS total_profit
FROM 
    dmsales
GROUP BY 
    customer_id, customer_name
ORDER BY 
    total_sales DESC;

-- R2: Group customers by market segment and 
-- provide the total number of customers, average sales
-- per customer, and total profit per segment.

SELECT
	market_segment,
	-- customer_id,customer_name,
	count(distinct customer_id) as total_customers,
	round(avg(total_sales),2) as average_sales,
	round(sum(profit),2) as total_profit
FROM DMSAles
GROUP BY market_segment
ORDER BY total_customers DESC;

-- R3 Identify the top 10 customers by total sales and their respective regions.
SELECT top 10 customer_id,
	customer_name,region,
	round(sum(total_sales),2) as customer_sales
FROM DMSales
GROUP BY customer_id,customer_name,region
ORDER BY customer_sales desc;

-- R4: Identify which products are most popular in each market segment
SELECT
	market_segment,
	product_name,
	sum(quantity) as total_quantity
FROM DMSales
GROUP BY market_segment,product_name
ORDER BY market_segment, total_quantity DESC;

-- Bonus -- 
WITH RankedProducts AS (
    SELECT 
        market_segment,
        product_id,
        product_name,
        SUM(quantity) AS total_quantity_sold,
        ROW_NUMBER() OVER (PARTITION BY market_segment ORDER BY SUM(quantity) DESC) AS product_rank
    FROM 
        DMsales
    GROUP BY 
        market_segment, product_id, product_name
)
SELECT 
    market_segment,
    product_id,
    product_name,
    total_quantity_sold
FROM 
    RankedProducts
WHERE 
    product_rank <= 2
ORDER BY 
    market_segment, product_rank;

-- R5: Analyze customer purchasing frequency 
-- (e.g., customers who have made more than 3
- purchases).

SELECT customer_id,
	customer_name,
	count(*) as order_count
FROM DMSales
GROUP BY customer_id,customer_name
HAVING count(*) >3
ORDER BY order_count DESC;
