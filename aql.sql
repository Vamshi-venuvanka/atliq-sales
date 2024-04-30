USE gdb023;

RENAME TABLE dim_customer TO customer;
RENAME TABLE dim_product TO product;
RENAME TABLE fact_gross_price TO gross_price;
RENAME TABLE fact_manufacturing_cost TO manufacturing_cost;
RENAME TABLE fact_pre_invoice_deductions TO pre_invoice_deductions;
RENAME TABLE fact_sales_monthly TO sales_monthly;

-- Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
SELECT 
      DISTINCT customer.market
FROM 
       customer
WHERE 
       customer.customer="Atliq Exclusive" AND customer.region="APAC";

-- What is the percentage of unique product increase in 2021 vs. 2020? The
-- final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg
WITH CTE AS(
SELECT COUNT(DISTINCT(sales_monthly.product_code)) AS unique_products_2020
FROM sales_monthly
WHERE sales_monthly.fiscal_year=2020
),
 CTE2 AS(
SELECT COUNT(DISTINCT(sales_monthly.product_code)) AS unique_products_2021
FROM sales_monthly
WHERE sales_monthly.fiscal_year=2021
)
SELECT *,
ROUND((unique_products_2021-unique_products_2020)*100/unique_products_2020,2) AS percentage_chg
FROM CTE,CTE2;


-- Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains 2 fields,
-- segment
-- product_count

SELECT 
COUNT(DISTINCT product.product_code) AS product_count,
product.segment
FROM product
GROUP BY product.segment
ORDER BY product_count DESC;

-- Follow-up: Which segment had the most increase in unique products in 
-- 2021 vs 2020? The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference
WITH CTE AS(
SELECT product.segment,COUNT(DISTINCT(sales_monthly.product_code)) AS products_2020
FROM sales_monthly
JOIN product
ON product.product_code=sales_monthly.product_code
WHERE sales_monthly.fiscal_year=2020
GROUP BY product.segment
ORDER BY products_2020 DESC),
CTE2 AS(
SELECT product.segment,COUNT(DISTINCT(sales_monthly.product_code)) AS products_2021
FROM sales_monthly
JOIN product
ON product.product_code=sales_monthly.product_code
WHERE sales_monthly.fiscal_year=2021
GROUP BY product.segment
ORDER BY products_2021 DESC
)
SELECT CTE.segment,CTE.products_2020,CTE2.products_2021,
CTE2.products_2021-CTE.products_2020 AS difference
FROM CTE
JOIN CTE2
ON CTE.segment=CTE2.segment
ORDER BY difference DESC;



-- Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
 -- product
-- manufacturing_cost

(SELECT DISTINCT product.product_code, product.product,manufacturing_cost.manufacturing_cost AS manufacturing_cost
FROM product
RIGHT JOIN manufacturing_cost
ON product.product_code=manufacturing_cost.product_code
GROUP BY product.product_code,product.product,manufacturing_cost.manufacturing_cost
ORDER BY manufacturing_cost DESC
LIMIT 1)
UNION
(SELECT DISTINCT product.product_code, product.product,manufacturing_cost.manufacturing_cost AS manufacturing_cost
FROM product
RIGHT JOIN manufacturing_cost
ON product.product_code=manufacturing_cost.product_code
GROUP BY product.product_code,product.product,manufacturing_cost.manufacturing_cost
ORDER BY manufacturing_cost ASC
LIMIT 1);

SELECT MIN(manufacturing_cost.manufacturing_cost)
FROM manufacturing_cost;
-- Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage

SELECT DISTINCT(customer.customer_code) AS customer_code,
customer.customer AS customer,
AVG(pre_invoice_deductions.pre_invoice_discount_pct) AS pre_invoice_discount_pct
FROM customer
LEFT JOIN pre_invoice_deductions
ON customer.customer_code=pre_invoice_deductions.customer_code
WHERE pre_invoice_deductions.fiscal_year=2021 and customer.market="India"
GROUP BY customer.customer_code,customer.customer
ORDER BY pre_invoice_discount_pct DESC
LIMIT 5;


-- Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount

SELECT DATE_FORMAT(sales_monthly.date,'%b') AS month_name,
DATE_FORMAT(sales_monthly.date,'%y') AS year_,
ROUND(SUM(sales_monthly.sold_quantity*gross_price.gross_price),2) AS Gross_Sales_amount
FROM sales_monthly
JOIN gross_price
ON gross_price.product_code=sales_monthly.product_code
JOIN customer
ON customer.customer_code=sales_monthly.customer_code
WHERE customer.customer="Atliq Exclusive"
GROUP BY DATE_FORMAT(sales_monthly.date,'%b'),DATE_FORMAT(sales_monthly.date,'%y')
ORDER BY year_ ASC;

-- In which quarter of 2020, got the maximum total_sold_quantity? The final
-- output contains these fields sorted by the total_sold_quantity,
 -- Quarter
-- total_sold_quantity

SELECT
CASE
WHEN sales_monthly.date BETWEEN '2019-09-01' AND '2019-11-01' THEN 'Q1'
WHEN sales_monthly.date BETWEEN '2019-12-01' AND '2020-02-01' THEN 'Q2'
WHEN sales_monthly.date BETWEEN '2020-03-01' AND '2020-05-01' THEN 'Q3'
WHEN sales_monthly.date BETWEEN '2020-06-01' AND '2020-08-01' THEN 'Q4'
END AS "Quarters",
ROUND(SUM(sales_monthly.sold_quantity),2) AS total_sold_quantity
FROM sales_monthly
WHERE sales_monthly.fiscal_year=2020
GROUP BY Quarters
ORDER BY total_sold_quantity DESC;

-- Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
-- channel
-- gross_sales_mln
-- percentag

WITH CTE AS(
SELECT customer.channel,SUM(sales_monthly.sold_quantity*gross_price.gross_price) AS total_quantity
FROM sales_monthly
JOIN gross_price
ON sales_monthly.product_code=gross_price.product_code
JOIN customer
ON sales_monthly.customer_code=customer.customer_code
WHERE sales_monthly.fiscal_year=2021
GROUP BY customer.channel)
SELECT channel,ROUND(total_quantity/1000000,2) AS total_quantity,
ROUND(total_quantity/(SUM( total_quantity) OVER())*100,2) AS percentage
FROM CTE
ORDER BY percentage DESC ;

-- Get the Top 3 products in each division that have a high
-- total_sold_quantity in the fiscal_year 2021? The final output contains these
-- fields,
-- division
-- product_code


WITH CTE AS(
SELECT sales_monthly.product_code,product.product,product.division,
ROUND(SUM(sales_monthly.sold_quantity),2) AS total_quantity,
RANK() OVER(PARTITION BY product.division ORDER BY SUM(sales_monthly.sold_quantity) DESC) AS row_num
FROM product 
LEFT JOIN sales_monthly
ON product.product_code=sales_monthly.product_code
WHERE sales_monthly.fiscal_year=2021
GROUP BY product.product_code,product.product,product.division)
SELECT *
FROM CTE
WHERE row_num in(1,2,3);