USE furniture_mart
GO

---  Project 5: Shipping and Logistics Optimization
---   Objective: Optimize shipping processes by analyzing delivery times and costs
-- Requirements:

-- 1. Calculate the average shipping time for each shipping mode by comparing order date and ship
 -- date.
 SELECT 
    ship_mode, 
    AVG(DATEDIFF(DAY, order_date, ship_date)) AS average_shipping_time
FROM 
    Sales
GROUP BY 
    ship_mode;

--  2. Identify the regions with the longest average shipping times.

SELECT 
    region, 
    AVG(DATEDIFF(DAY, order_date, ship_date)) AS average_shipping_time
FROM 
    Sales
GROUP BY 
    region
ORDER BY average_shipping_time desc;

--  3. Provide insights into which shipping mode yields the highest profit margin.
SELECT 
    ship_mode, 
    ROUND(SUM(profit) / SUM(total_sales) * 100, 2) AS profit_margin
FROM 
    sales
GROUP BY 
    ship_mode
ORDER BY 
    profit_margin DESC;

--- 3A. Identify which product sub-categories has the highest profit margin.
SELECT 
    sub_category, 
    ROUND(SUM(profit) / SUM(total_sales) * 100, 2) AS profit_margin
FROM 
    sales
GROUP BY 
    sub_category
ORDER BY 
    profit_margin DESC;
-- 3B. Products ranked by profit margin top 10

SELECT top 10
    product_name, 
    ROUND(SUM(profit) / SUM(total_sales) * 100, 2) AS profit_margin
FROM 
    sales
GROUP BY 
    product_name
ORDER BY 
    profit_margin DESC;
--  4. Analyze any correlations between shipping times and total sales or customer satisfaction (if data
--  is available).
WITH ShippingTimes AS (
    SELECT 
        order_id,
        DATEDIFF(DAY, order_date, ship_date) AS shipping_time,
        total_sales
    FROM 
        sales
)
SELECT 
    shipping_time,
    round(AVG(total_sales),2) AS average_total_sales
FROM 
    ShippingTimes
GROUP BY 
    shipping_time
ORDER BY 
    shipping_time;

 -- 5. Recommend the best shipping modes for high-value customers based on historical data.
 -- Identify high-value customers (e.g., total sales > 10,000)
WITH HighValueCustomers AS (
    SELECT 
        customer_id, 
        customer_name, 
        SUM(total_sales) AS total_sales
    FROM 
        sales
    GROUP BY 
        customer_id, customer_name
    HAVING 
        SUM(total_sales) > 5000
)

-- Recommend best shipping modes for high-value customers based on profit margin
SELECT 
    hvc.customer_id, 
    hvc.customer_name, 
    s.ship_mode, 
    ROUND(SUM(s.profit) / SUM(s.total_sales) * 100, 2) AS profit_margin,
    AVG(DATEDIFF(DAY, s.order_date, s.ship_date)) AS average_shipping_time
FROM 
    sales s
JOIN 
    HighValueCustomers hvc ON s.customer_id = hvc.customer_id
GROUP BY 
    hvc.customer_id, hvc.customer_name, s.ship_mode
ORDER BY 
    profit_margin DESC;


