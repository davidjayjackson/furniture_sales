USE furniture_store
GO

--- Project 1: Basic Sales Reporting
-- Objective: Create simple reports to track key performance metrics.

--- 1.  Generate a report that shows total sales, total quantity, 
--- and total profit for the entire year.
SELECT DATEPART(year, order_date) as sales_year,
round(sum(total_sales),2)as total_sales,
round(sum(quantity),2) as total_quantity,
round(sum(profit),2) as total_profit
FROM DMSales
GROUP BY DATEPART(year, order_date)
ORDER BY DATEPART(year, order_date);

--- 2. Create a summary table showing total sales by month.

SELECT 
    YEAR(order_date) AS order_year,
    FORMAT(order_date, 'MMMM') AS order_month_name,
    MONTH(order_date) AS order_month_number,
    ROUND(SUM(total_sales), 2) AS total_sales
FROM DMSales
GROUP BY YEAR(order_date), MONTH(order_date), FORMAT(order_date, 'MMMM')
ORDER BY YEAR(order_date), MONTH(order_date);

--- 3. Provide a breakdown of sales by product category and sub-category

SELECT category,sub_category,
		round(sum(total_sales),2) as total_sales
		FROM DMSales
		GROUP BY category,sub_category
		ORDER BY category,sub_category;

--- 4. Identify the top 10 products by total sales.
SELECT top 10 product_name,
	round(sum(total_sales),2) as total_sales
	FROM DMSales
	GROUP BY product_name
	ORDER BY total_sales DESC;

--- 5. Write queries that summarize total sales, 
-- total profit, and total discount by shipping mode.
SELECT ship_mode,
	round(sum(total_sales),2) as total_sales,
	round(sum(profit),2) as total_profit,
	round(sum(discount),2)  as total_discount
	FROM DMSales
	GROUP BY ship_mode
	ORDER BY total_sales desc;