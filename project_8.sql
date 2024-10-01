USE furniture_mart
GO

-- Project 8: Predictive Sales Analytics
-- Objective: Use historical sales data to forecast future sales and trends.

 -- Requirements:
-- 1. Identify seasonal trends by analyzing sales data from previous years and group them by month.
SELECT 
    YEAR(order_date) AS Year,
    MONTH(order_date) AS Month,
    SUM(total_sales) AS TotalSales
FROM 
    [dbo].[Sales]
WHERE 
    category = 'Furniture'
GROUP BY 
    YEAR(order_date), MONTH(order_date)
ORDER BY 
    YEAR(order_date), MONTH(order_date);

-- 2. Use SQL queries to generate a rolling 12-month sales forecast based on historical sales.
WITH SalesByMonth AS (
    SELECT 
        YEAR(order_date) AS Year,
        MONTH(order_date) AS Month,
        DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS SalesMonth,
        SUM(total_sales) AS TotalSales
    FROM 
        [dbo].[Sales]
    WHERE 
        category = 'Furniture'
    GROUP BY 
        YEAR(order_date), MONTH(order_date)
)
SELECT 
    SalesMonth,
    SUM(TotalSales) OVER (
        ORDER BY SalesMonth 
        ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
    ) AS Rolling12MonthSales
FROM 
    SalesByMonth
ORDER BY 
    SalesMonth;

-- 3. Predict which product sub-categories are likely to see increased sales in the upcoming months based
-- on past trends.
WITH MonthlySales AS (
    SELECT 
        CONCAT(YEAR(order_date), '-', RIGHT('00' + CAST(MONTH(order_date) AS VARCHAR(2)), 2)) AS YearMonth,
        sub_category,
        SUM(total_sales) AS TotalSales
    FROM 
        [dbo].[Sales]
    WHERE 
        category = 'Furniture'
    GROUP BY 
        YEAR(order_date), MONTH(order_date), sub_category
),
SalesWithPreviousMonth AS (
    SELECT 
        ms.YearMonth,
        ms.sub_category,
        ms.TotalSales,
        LAG(ms.TotalSales, 1) OVER (PARTITION BY ms.sub_category ORDER BY ms.YearMonth) AS PreviousMonthSales
    FROM 
        MonthlySales ms
)
SELECT 
    YearMonth,
    sub_category,
    TotalSales,
    PreviousMonthSales,
    CASE 
        WHEN PreviousMonthSales IS NOT NULL AND PreviousMonthSales > 0 THEN 
            ((TotalSales - PreviousMonthSales) / PreviousMonthSales) * 100 
        ELSE NULL 
    END AS MonthlyGrowthRate
FROM 
    SalesWithPreviousMonth
ORDER BY 
    sub_category, YearMonth;

-- 4. Create a forecasting report that breaks down future sales expectations by region and market
-- segment.WITH MonthlySales AS (

WITH MonthlySales AS (
    SELECT 
        CONCAT(YEAR(order_date), '-', RIGHT('00' + CAST(MONTH(order_date) AS VARCHAR(2)), 2)) AS YearMonth,
        region,
        market_segment,
        SUM(CAST(total_sales AS FLOAT)) AS TotalSales
    FROM 
        [dbo].[Sales]
    WHERE 
        category = 'Furniture'
    GROUP BY 
        YEAR(order_date), MONTH(order_date), region, market_segment
),
SalesWithPreviousMonth AS (
    SELECT 
        ms.YearMonth,
        ms.region,
        ms.market_segment,
        ms.TotalSales,
        LAG(ms.TotalSales, 1) OVER (PARTITION BY ms.region, ms.market_segment ORDER BY ms.YearMonth) AS PreviousMonthSales
    FROM 
        MonthlySales ms
)
SELECT 
    YearMonth,
    region,
    market_segment,
    TotalSales,
    PreviousMonthSales,
    CASE 
        WHEN PreviousMonthSales IS NOT NULL AND PreviousMonthSales > 0 THEN 
            ((TotalSales - PreviousMonthSales) / PreviousMonthSales) * 100 
        ELSE 0 
    END AS MonthlyGrowthRate
FROM 
    SalesWithPreviousMonth
ORDER BY 
    region, YearMonth;



-- 5. Suggest potential growth strategies for underperforming categories based on past data analysis.

