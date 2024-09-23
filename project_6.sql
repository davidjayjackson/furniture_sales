USE furniture_mart
GO

-- Project 6: Customer Retention and Loyalty Analysis
-- Objective: Analyze customer retention and create strategies for improving customer loyalty
-- Github: https://github.com/davidjayjackson/furniture_sales

-- Requirements:
-- 1. Calculate the retention rate by analyzing customers who made repeat purchases in consecutive
-- years.(order_date range: 2014-01-06 - 2017-12-30)

WITH CustomerYearlyPurchases AS (
    -- Step 1: Extract year from order_date and identify customer purchases by year
    SELECT 
        customer_id,
        YEAR(order_date) AS purchase_year
    FROM dbo.Sales
    WHERE order_date BETWEEN '2014-01-06' AND '2017-12-30'
    GROUP BY customer_id, YEAR(order_date)
),
CustomerRetention AS (
    -- Step 2: Identify customers who made repeat purchases in consecutive years
    SELECT 
        cy1.customer_id,
        cy1.purchase_year AS current_year,
        cy2.purchase_year AS previous_year
    FROM CustomerYearlyPurchases cy1
    JOIN CustomerYearlyPurchases cy2
        ON cy1.customer_id = cy2.customer_id
        AND cy1.purchase_year = cy2.purchase_year + 1
),
YearlyRetention AS (
    -- Step 3: Calculate the retention rate for each year
    SELECT 
        current_year,
        COUNT(DISTINCT customer_id) AS retained_customers
    FROM CustomerRetention
    GROUP BY current_year
),
TotalCustomers AS (
    -- Step 4: Calculate total unique customers per year
    SELECT 
        YEAR(order_date) AS order_year,
        COUNT(DISTINCT customer_id) AS total_customers
    FROM dbo.Sales
    WHERE order_date BETWEEN '2014-01-06' AND '2017-12-30'
    GROUP BY YEAR(order_date)
)
-- Step 5: Calculate the retention rate as the percentage of customers retained
SELECT 
    tr.current_year AS Year,
    tr.retained_customers AS RetainedCustomers,
    tc.total_customers AS TotalCustomers,
    (CAST(tr.retained_customers AS FLOAT) / tc.total_customers) * 100 AS RetentionRate
FROM YearlyRetention tr
JOIN TotalCustomers tc
    ON tr.current_year = tc.order_year
ORDER BY tr.current_year;


-- 2. Identify customers who have not made a purchase in over 12 months and create a list for a
--  re-engagement marketing campaign.
WITH LastPurchase AS (
    -- Step 1: Identify the most recent purchase date for each customer
    SELECT 
        customer_id,
        MAX(order_date) AS last_order_date
    FROM dbo.Sales
    WHERE order_date BETWEEN '2014-01-06' AND '2017-12-30'
    GROUP BY customer_id
),
InactiveCustomers AS (
    -- Step 2: Find customers who have not made a purchase in the last 12 months
    SELECT 
        customer_id,
        last_order_date,
        DATEDIFF(month, last_order_date, '2017-12-30') AS months_since_last_purchase
    FROM LastPurchase
    WHERE DATEDIFF(month, last_order_date, '2017-12-30') > 12
)
-- Step 3: Create the final list for re-engagement marketing campaign (excluding email)
SELECT 
    ic.customer_id,
    c.customer_name,
    ic.last_order_date,
    ic.months_since_last_purchase
FROM InactiveCustomers ic
JOIN dbo.Sales c
    ON ic.customer_id = c.customer_id
GROUP BY ic.customer_id, c.customer_name, ic.last_order_date, ic.months_since_last_purchase
ORDER BY ic.months_since_last_purchase DESC;

-- 3. Create a customer lifetime value (CLV) metric that calculates the total profit from each customer
--  over time.
WITH CustomerProfit AS (
    -- Step 1: Calculate total profit and total sales for each customer
    SELECT 
        customer_id,
        customer_name,
        SUM(profit) AS total_profit,
        SUM(total_sales) AS total_sales
    FROM dbo.Sales
    WHERE order_date BETWEEN '2014-01-06' AND '2017-12-30'
    GROUP BY customer_id, customer_name
)
-- Step 2: Display the customer lifetime value (CLV) as the total profit per customer
SELECT 
    customer_id,
    customer_name,
    total_profit AS CustomerLifetimeValue,
    total_sales AS TotalSales -- Optional: Display total sales if needed
FROM CustomerProfit
ORDER BY total_profit DESC;  -- Sort by highest lifetime value (profit)

-- 4. Determine which customer segments (market segments, regions) have the highest and lowest
-- retention rates.
WITH CustomerYearlyPurchases AS (
    -- Step 1: Extract year from order_date and group purchases by customer, market segment, and region
    SELECT 
        customer_id,
        market_segment,
        region,
        YEAR(order_date) AS purchase_year
    FROM dbo.Sales
    WHERE order_date BETWEEN '2014-01-06' AND '2017-12-30'
    GROUP BY customer_id, market_segment, region, YEAR(order_date)
),
CustomerRetention AS (
    -- Step 2: Identify customers who made purchases in consecutive years, grouped by segment
    SELECT 
        cy1.customer_id,
        cy1.market_segment,
        cy1.region,
        cy1.purchase_year AS current_year,
        cy2.purchase_year AS previous_year
    FROM CustomerYearlyPurchases cy1
    JOIN CustomerYearlyPurchases cy2
        ON cy1.customer_id = cy2.customer_id
        AND cy1.purchase_year = cy2.purchase_year + 1
        AND cy1.market_segment = cy2.market_segment
        AND cy1.region = cy2.region
),
YearlyRetentionBySegment AS (
    -- Step 3: Calculate the number of retained customers for each market segment and region
    SELECT 
        current_year,
        market_segment,
        region,
        COUNT(DISTINCT customer_id) AS retained_customers
    FROM CustomerRetention
    GROUP BY current_year, market_segment, region
),
TotalCustomersBySegment AS (
    -- Step 4: Calculate total unique customers per year by segment
    SELECT 
        YEAR(order_date) AS order_year,
        market_segment,
        region,
        COUNT(DISTINCT customer_id) AS total_customers
    FROM dbo.Sales
    WHERE order_date BETWEEN '2014-01-06' AND '2017-12-30'
    GROUP BY YEAR(order_date), market_segment, region
)
-- Step 5: Calculate retention rates and identify highest/lowest retention segments
SELECT 
    tr.current_year AS Year,
    tr.market_segment,
    tr.region,
    tr.retained_customers,
    tc.total_customers,
    (CAST(tr.retained_customers AS FLOAT) / tc.total_customers) * 100 AS RetentionRate
FROM YearlyRetentionBySegment tr
JOIN TotalCustomersBySegment tc
    ON tr.current_year = tc.order_year
    AND tr.market_segment = tc.market_segment
    AND tr.region = tc.region
ORDER BY RetentionRate DESC;  -- Sort by highest retention rate

-- 5. Track customer purchasing patterns and identify potential churn risks based on inactivity or
--  reduced purchasing frequency
WITH CustomerPurchases AS (
    -- Step 1: Extract customer purchases with year and month for tracking frequency
    SELECT 
        customer_id,
        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,
        COUNT(order_id) AS monthly_purchases
    FROM dbo.Sales
    WHERE order_date BETWEEN '2014-01-06' AND '2017-12-30'
    GROUP BY customer_id, YEAR(order_date), MONTH(order_date)
),
CustomerPurchaseFrequency AS (
    -- Step 2: Calculate average monthly purchase frequency for each customer
    SELECT 
        customer_id,
        AVG(monthly_purchases) AS avg_monthly_purchases,
        MAX(order_year * 100 + order_month) AS last_purchase_ym -- Combines year and month for last purchase
    FROM CustomerPurchases
    GROUP BY customer_id
),
CustomerChurnRisk AS (
    -- Step 3: Identify potential churn risks based on long inactivity or reduced purchasing frequency
    SELECT 
        cpf.customer_id,
        cpf.avg_monthly_purchases,
        cpf.last_purchase_ym,
        DATEDIFF(month, CAST(CONCAT(LEFT(cpf.last_purchase_ym, 4), '-', RIGHT(cpf.last_purchase_ym, 2), '-01') AS DATE), '2017-12-30') AS months_since_last_purchase,
        CASE 
            WHEN DATEDIFF(month, CAST(CONCAT(LEFT(cpf.last_purchase_ym, 4), '-', RIGHT(cpf.last_purchase_ym, 2), '-01') AS DATE), '2017-12-30') > 6 THEN 'High Risk'  -- High risk if no purchase in last 6 months
            WHEN avg_monthly_purchases < 1 THEN 'Medium Risk' -- Medium risk if average purchases fall below 1 per month
            ELSE 'Low Risk' -- Low risk if customer still purchases regularly
        END AS churn_risk
    FROM CustomerPurchaseFrequency cpf
),
ChurnRiskCounts AS (
    -- Step 4: Calculate total customers per risk level
    SELECT 
        churn_risk,
        COUNT(customer_id) AS customer_count
    FROM CustomerChurnRisk
    GROUP BY churn_risk
),
TotalCustomers AS (
    -- Step 5: Calculate the total number of customers
    SELECT COUNT(DISTINCT customer_id) AS total_customers
    FROM dbo.Sales
    WHERE order_date BETWEEN '2014-01-06' AND '2017-12-30'
)
-- Step 6: Calculate percentage of total customers for each churn risk level
SELECT 
    crc.churn_risk,
    crc.customer_count,
    tc.total_customers,
    (CAST(crc.customer_count AS FLOAT) / tc.total_customers) * 100 AS percent_of_total
FROM ChurnRiskCounts crc
CROSS JOIN TotalCustomers tc
ORDER BY percent_of_total DESC;

-- 5A Customer Risk List.
WITH CustomerPurchases AS (
    -- Step 1: Extract customer purchases with year and month for tracking frequency
    SELECT 
        customer_id,
        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,
        COUNT(order_id) AS monthly_purchases
    FROM dbo.Sales
    WHERE order_date BETWEEN '2014-01-06' AND '2017-12-30'
    GROUP BY customer_id, YEAR(order_date), MONTH(order_date)
),
CustomerPurchaseFrequency AS (
    -- Step 2: Calculate average monthly purchase frequency for each customer
    SELECT 
        customer_id,
        AVG(monthly_purchases) AS avg_monthly_purchases,
        MAX(order_year * 100 + order_month) AS last_purchase_ym -- Combines year and month for last purchase
    FROM CustomerPurchases
    GROUP BY customer_id
),
CustomerChurnRisk AS (
    -- Step 3: Identify potential churn risks based on long inactivity or reduced purchasing frequency
    SELECT 
        cpf.customer_id,
        cpf.avg_monthly_purchases,
        cpf.last_purchase_ym,
        DATEDIFF(month, CAST(CONCAT(LEFT(cpf.last_purchase_ym, 4), '-', RIGHT(cpf.last_purchase_ym, 2), '-01') AS DATE), '2017-12-30') AS months_since_last_purchase,
        CASE 
            WHEN DATEDIFF(month, CAST(CONCAT(LEFT(cpf.last_purchase_ym, 4), '-', RIGHT(cpf.last_purchase_ym, 2), '-01') AS DATE), '2017-12-30') > 6 THEN 'High Risk'  -- High risk if no purchase in last 6 months
            WHEN avg_monthly_purchases < 1 THEN 'Medium Risk' -- Medium risk if average purchases fall below 1 per month
            ELSE 'Low Risk' -- Low risk if customer still purchases regularly
        END AS churn_risk
    FROM CustomerPurchaseFrequency cpf
)
-- Step 4: Display customers with their churn risk
SELECT 
    customer_id,
    avg_monthly_purchases,
    months_since_last_purchase,
    churn_risk
FROM CustomerChurnRisk
ORDER BY churn_risk DESC, months_since_last_purchase DESC;
