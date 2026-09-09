-- SQL Task -- Analyze sales performance over time

-- we can analyze the data by years
-- the below query can be customized in plenty of ways
-- In place of YEAR we can add DATE and AS order_date
-- we can add SUM, we can add count distinct, we can do Group by & order by


CREATE SCHEMA gold;

ALTER SCHEMA gold TRANSFER dbo.[gold.dim_customers];

ALTER SCHEMA gold TRANSFER dbo.[gold.products];


USE DATAWAREHOUSEANALYSIS;

select
YEAR(order_date) AS order_year,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) as total_customers ,
SUM(quantity) as total_quantity
from [gold.fact_sales]
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
order by YEAR(order_date)

-- we can also aggregate the above data by months 
-- By performing changes over months, we can get a detailed insight to discover seasonality in data.

SELECT
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM dbo.[gold.fact_sales]
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date);

-- we can also determine output by year & month 
-- BY THE BELOW QUERY UNDER THE ORDER_DATE COLUMN, THE OUTPUT WILL HAVE FIRST DAY OF EACH MONTH

SELECT
DATETRUNC(YEAR,ORDER_DATE) AS ORDER_DATE,
SUM(SALES_AMOUNT) AS TOTAL_SALES,
COUNT(DISTINCT CUSTOMER_KEY) AS TOTAL_CUSTOMERS,
SUM(QUANTITY) AS TOTAL_QUANTITY
FROM DBO.[gold.fact_sales]
WHERE ORDER_DATE IS NOT NULL
GROUP BY DATETRUNC(YEAR, ORDER_DATE)
ORDER BY DATETRUNC(YEAR, ORDER_DATE)

-- 
SELECT
FORMAT(ORDER_DATE, 'YYYY-MMM') AS ORDER_DATE,
SUM(SALES_AMOUNT) AS TOTAL_SALES,
COUNT(DISTINCT CUSTOMER_KEY) AS TOTAL_CUSTOMERS,
SUM(QUANTITY) AS TOTAL_QUANTITY
FROM DBO.[gold.fact_sales]
WHERE ORDER_DATE IS NOT NULL
GROUP BY FORMAT(ORDER_DATE, 'YYYY-MMM')
ORDER BY FORMAT(ORDER_DATE, 'YYYY-MMM')


-- SQL TASK - calculate the total sales per month and running total of sales over time.
-- CUMMULATIVE ANALYSIS
-- aggregate functions

-- we can change the granularity from date to the month 


SELECT
ORDER_DATE,
TOTAL_SALES,
SUM(TOTAL_SALES) OVER (PARTITION BY ORDER_DATE ORDER BY ORDER_DATE) AS RUNNING_TOTAL_SALES
FROM
(
SELECT
DATETRUNC(YEAR, order_date) AS ORDER_DATE,
SUM(sales_amount) AS TOTAL_SALES
from DBO.[gold.fact_sales]
WHERE ORDER_DATE IS NOT NULL
GROUP BY DATETRUNC(YEAR, ORDER_DATE)
) T 

-- CUMMULATIVE TOTAL CAN BE DONE OVER THE YEAR AS WELL

SELECT
ORDER_DATE,
TOTAL_SALES,
SUM(TOTAL_SALES) OVER (ORDER BY ORDER_DATE) AS RUNNING_TOTAL_SALES
FROM
(
SELECT
DATETRUNC(YEAR, order_date) AS ORDER_DATE,
SUM(sales_amount) AS TOTAL_SALES
from DBO.[gold.fact_sales]
WHERE ORDER_DATE IS NOT NULL
GROUP BY DATETRUNC(YEAR, ORDER_DATE)
) T 

-- INSTEAD OF RUNNING TOTAL, WE CAN ALSO FIND MOVING AVERAGE

SELECT
ORDER_DATE,
TOTAL_SALES,
SUM(TOTAL_SALES) OVER (ORDER BY ORDER_DATE) AS RUNNING_TOTAL_SALES,
AVG(avg_price) OVER (ORDER BY ORDER_DATE) AS MOVING_AVERAGE_PRICE
FROM
(
SELECT
DATETRUNC(YEAR, order_date) AS ORDER_DATE,
SUM(sales_amount) AS TOTAL_SALES,
AVG(PRICE) AS AVG_PRICE
from DBO.[gold.fact_sales]
WHERE ORDER_DATE IS NOT NULL
GROUP BY DATETRUNC(YEAR, ORDER_DATE)
) T 

-- PERFORMANCE ANALYSIS 
-- SQL TASK -- COMPARING THE CURRENT VALUE TO A TARGET VALUE 
-- HELPS MEASURE SUCCESS AND COMPARE PERFORMANCE 
-- DIFFERENCE BETWEEN CURRENT MEASURE - TARGET MEASURE 


-- Analyze the yearly performance of products by comparing each product's sales to both 
-- its average sales performance and the previous year sales 

WITH yearly_product_sales AS (
SELECT
YEAR(f.order_date) AS ORDER_YEAR,
p.product_name,
SUM(f.sales_amount) AS current_sales
FROM [gold.fact_sales] f
LEFT JOIN dbo.[gold.dim_products] p
ON f.product_key = p.product_key 
WHERE f.order_date IS NOT NULL
GROUP BY 
YEAR(f.order_date),
p.product_name
)

SELECT
order_year,
product_name,
current_sales,
AVG(CURRENT_SALES) OVER (PARTITION BY PRODUCT_NAME) AVG_SALES,
current_sales - avg(CURRENT_SALES) OVER (PARTITION BY PRODUCT_NAME) AS DIFF_AVG,
CASE WHEN current_sales - AVG(CURRENT_SALES) OVER (PARTITION BY PRODUCT_NAME) > 0 THEN 'ABOVE AVG'
     WHEN current_sales - AVG(CURRENT_SALES) OVER (PARTITION BY PRODUCT_NAME) > 0 THEN 'BELOW AVG'
     ELSE 'AVG'
END AVG_CHANGE
FROM yearly_product_sales
ORDER BY product_name, ORDER_YEAR

-- LETS SAY now we want to access previous year

WITH yearly_product_sales AS (
SELECT
YEAR(f.order_date) AS ORDER_YEAR,
p.product_name,
SUM(f.sales_amount) AS current_sales
FROM [gold.fact_sales] f
LEFT JOIN dbo.[gold.dim_products] p
ON f.product_key = p.product_key 
WHERE f.order_date IS NOT NULL
GROUP BY 
YEAR(f.order_date),
p.product_name
)

SELECT
order_year,
product_name,
current_sales,
AVG(CURRENT_SALES) OVER (PARTITION BY PRODUCT_NAME) AVG_SALES,
current_sales - avg(CURRENT_SALES) OVER (PARTITION BY PRODUCT_NAME) AS DIFF_AVG,
CASE WHEN current_sales - AVG(CURRENT_SALES) OVER (PARTITION BY PRODUCT_NAME) > 0 THEN 'ABOVE AVG'
     WHEN current_sales - AVG(CURRENT_SALES) OVER (PARTITION BY PRODUCT_NAME) > 0 THEN 'BELOW AVG'
     ELSE 'AVG'
END AVG_CHANGE,
lag(current_sales) over (partition by product_name order by order_year) py_sales,
current_sales - LAG(current_sales) over (partition by product_name order by order_year) AS diff_py
FROM yearly_product_sales
ORDER BY product_name, ORDER_YEAR

-- BY DOING THIS WE CAN CALCULATE THE DIFFERENCE BETWEEN CURRENT SALES AND PREVIOUS YEAR SALES


WITH yearly_product_sales AS (
SELECT
YEAR(f.order_date) AS ORDER_YEAR,
p.product_name,
SUM(f.sales_amount) AS current_sales
FROM [gold.fact_sales] f
LEFT JOIN dbo.[gold.dim_products] p
ON f.product_key = p.product_key 
WHERE f.order_date IS NOT NULL
GROUP BY 
YEAR(f.order_date),
p.product_name
)

SELECT
order_year,
product_name,
current_sales,
AVG(CURRENT_SALES) OVER (PARTITION BY PRODUCT_NAME) AVG_SALES,
current_sales - avg(CURRENT_SALES) OVER (PARTITION BY PRODUCT_NAME) AS DIFF_AVG,
CASE WHEN current_sales - AVG(CURRENT_SALES) OVER (PARTITION BY PRODUCT_NAME) > 0 THEN 'ABOVE AVG'
     WHEN current_sales - AVG(CURRENT_SALES) OVER (PARTITION BY PRODUCT_NAME) > 0 THEN 'BELOW AVG'
     ELSE 'AVG'
END AVG_CHANGE,
-- YEAR- OVER- YEAR ANALYSIS

LAG(current_sales) over (partition by product_name order by order_year) py_sales,
current_sales - LAG(current_sales) over (partition by product_name order by order_year) AS diff_py,
CASE WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'INCREASE'
     WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0  THEN 'DECREASE'
ELSE 'NO CHANGE'
END PY_CHANGE
FROM yearly_product_sales
ORDER BY product_name, ORDER_YEAR


-- part to whole 
-- proportional analysis 
-- analyze how an individual part is performing compared to the overall,
-- allowing us to understand which category has the greatest impact on the business.
-- SQL TASK - WHICH CATEGORIES CONTRIBUTE the most to overall sales.

SELECT 
category,
SUM(SALES_AMOUNT) AS TOTAL_SALES
FROM GOLD.FACT_SALES F
LEFT JOIN GOLD.DIM_PRODUCTS P
ON P.PRODUCT_KEY = F.PRODUCT_KEY
GROUP BY CATEGORY;

-- so now we need total sales again by different granularity 
-- window functions -- to display aggregations at multiple levels in results, use window functions.

WITH category_sales AS (
    SELECT 
        category,
        SUM(sales_amount) AS total_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON p.product_key = f.product_key
    GROUP BY category
)

SELECT 
    category,
    total_sales,
    SUM(total_sales) OVER () AS overall_sales,
    CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER ())* 100, 2), '%') AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC;

-- DATA SEGMENTATION 
-- Group the data based on specific range, 
-- helps undertand the correlation between 2 measures 
-- [measure] by [measure]
-- SQL TASK -- segment products into cost ranges and count how many products fall into each segment.


with product_segments AS (
select 
product_key,
product_name,
cost,
CASE WHEN cost < 100 THEN 'Below 100'
     WHEN cost BETWEEN 100 AND 500 THEN '100-500'
     WHEN COST BETWEEN 500 AND 1000 THEN '500-1000'
     ELSE 'ABOVE 1000'
     END COST_RANGE
     FROM GOLD.DIM_PRODUCTS)

     SELECT
     cost_range,
     COUNT(PRODUCT_KEY) AS total_products
     FROM product_segments
     GROUP BY cost_range 
     order by total_products desc


-- SQL TASK 
-- Lets group customers into three segments based on their spending behaviour
-- vip - atleast 12 months of history and spending more than 5,000 euros
-- regular - atleast 12 months of history but spending 5,000 or less.
-- new - lifespan less than 12 months. 
-- find the total number of customers


WITH customer_spending AS (
SELECT 
c.customer_key,
SUM(f.sales_amount) AS total_spending,
min(order_date) as first_order,
max(order_date) as last_order,
DATEDIFF(MONTH, MIN(ORDER_DATE), MAX(ORDER_DATE)) AS LIFESPAN
from gold.fact_sales f
left join gold.dim_customers c 
on f.customer_key = c.customer_key
group by c.customer_key 
)

select 
customer_key,
total_spending,
lifespan,
CASE WHEN LIFESPAN >= 12 AND TOTAL_SPENDING > 5000 THEN 'VIP'
     WHEN LIFESPAN >= 12 AND TOTAL_SPENDING <= 5000 THEN 'REGULAR'
     ELSE 'New'
     END customer_segment
FROM customer_spending


-- basically we have derived a new dimension from 2 measures.

-- we have derived a new measure from a dimension order date
-- we are converting a dimension to a measure  & a measure to a new dimension -- thats what we analyze in SQL 





CREATE VIEW gold.report_customers AS 
WITH base_query AS (
/*-----------------------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
-------------------------------------------------------------------------------------*/
    SELECT
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        c.first_name,
        c.last_name,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        DATEDIFF(YEAR, c.birthdate, GETDATE()) AS age
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON c.customer_key = f.customer_key
    WHERE order_date IS NOT NULL
),

customer_aggregation AS (
/*--------------------------------------------------------------------------------------------------------
2) Customer Aggregation: Summarizes key metrics at the customer level 
---------------------------------------------------------------------------------------------------------*/
    SELECT  
        customer_key,
        customer_number,
        customer_name,
        age,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT product_key) AS total_products,
        MAX(order_date) AS last_order_date,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
    FROM base_query
    GROUP BY 
        customer_key,
        customer_number,
        customer_name,
        age
)

SELECT 
customer_key,
customer_number,
customer_name,
age,
CASE 
     WHEN age < 20 THEN 'Under 20'
     WHEN age between 20 and 29 THEN '20-29'
     WHEN age between 30 and 39 THEN '30-39'
     WHEN age between 40 and 49 THEN '40-49'
     ELSE '50 AND ABOVE'
     END AS AGE_GROUP,
CASE 
    WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
    WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
    ELSE 'New'
    END AS customer_segment,
    last_order_date,
    DATEDIFF (month, last_order_date, GETD()) AS recency,
    total_orders,
    total_sales,
    total_quantity,
    total_products
    lifespan
    -- Computate average order value (AVO)
    CASE WHEN total_orders = 0 THEN 0
         ELSE total_sales / total_orders
    END AS avg_order_value    
    -- compute average monthly spend
    CASE WHEN lifespan = 0 THEN total_sales
         ELSE total_sales / lifespan
    END AS avg_monthly_spend
    FROM customer_aggregation



/*-----------------------------------------------------------------------------------------------------------
BY THE END OF THIS QUERY, WE HAVE NOW CHANGED MEASURE INTO A DIMENSION 
we have fulfilled the requirement.
after this we will take the whole query and put it in the database as a view
and after that we can share it with the other data analyst in the team who can create a dashboard in order to 
visualize a data--- 
-- basically you will then put the query in the database so that others can use it 
-- if they can create ONE view, it will be much easier to consume 
-- Data analyst can then write a query on top of your view to generate quick insights.
-- last point, if you want the query to be used by others in the database, we can create VIEW 
---------------------------------------------------------------------------*/


CREATE VIEW gold.report_customers AS 
WITH base_query AS (
    -- 1) Base Query: Retrieves core columns from tables
    SELECT
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        c.first_name,
        c.last_name,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        DATEDIFF(YEAR, c.birthdate, GETDATE()) AS age
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON c.customer_key = f.customer_key
    WHERE order_date IS NOT NULL
),

customer_aggregation AS (
    -- 2) Customer Aggregation: Summarizes key metrics at the customer level
    SELECT  
        customer_key,
        customer_number,
        customer_name,
        age,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT product_key) AS total_products,
        MAX(order_date) AS last_order_date,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
    FROM base_query
    GROUP BY 
        customer_key,
        customer_number,
        customer_name,
        age
)

SELECT 
    customer_key,
    customer_number,
    customer_name,
    age,
    CASE 
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 AND ABOVE'
    END AS age_group,
    CASE 
        WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,
    last_order_date,
    DATEDIFF(MONTH, last_order_date, GETDATE()) AS recency,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    lifespan,
    -- Compute average order value (AOV)
    CASE WHEN total_orders = 0 THEN 0
         ELSE total_sales / total_orders
    END AS avg_order_value,
    -- Compute average monthly spend
    CASE WHEN lifespan = 0 THEN total_sales
         ELSE total_sales / lifespan
    END AS avg_monthly_spend
FROM customer_aggregation;

/*-------------------------------------------
SELECT * FROM gold.report_customers;
-------------------------------------------*/
-- this kind of reporting is important because you are giving the full picture, 360 degree view
-- details, categories, views

-- And based on just one view 
/*------------------------------------------
SELECT * FROM gold.report_customers
------------------------------------------*/

select
customer_segment,
COUNT(customer_number) AS total_customers,
SUM(total_sales) total_sales
FROM gold.report_customers
GROUP BY customer_Segment


--Build a second report
-- Complete insights


----------------------------------------------------------------------------------------------------------
/*----------------------------------------------------------------------------------------------------------
-- Purpose : This report consolidates  key product metrics and behaviours.

-- Highlights:
1. Gathers essential fields such as product_name, category, subcategory & cost.
2. Segments products by revenue to identify high perform, Mid - range or low performers.
3. Aggregate product level metrics
- total orders
- total sales
- total quantity sold
- total customers (unique)
- lifespan (in months)
4. Calcualtes valuable KPI's
- recency  (months since last sale)
- average order revenue (AOR)
- average monthly revenue 

---------------------------------------------------------------------------------------------------*/

CREATE VIEW gold.report_products AS
WITH base_query AS (
    -- 1) Base Query: retrieves core columns from fact_sales and dim_products
    SELECT
        f.order_number,
        f.order_date,
        f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE order_date IS NOT NULL -- only consider valid sales data
),

product_aggregations AS (
    -- 2) Product aggregations: Summarizes key metrics at the product level
    SELECT 
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
        MAX(order_date) AS last_sale_date,
        COUNT(DISTINCT order_number) AS total_orders,
        COUNT(DISTINCT customer_key) AS total_customers,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)), 1) AS avg_selling_price
    FROM base_query 
    GROUP BY 
        product_key,
        product_name,
        category, 
        subcategory,
        cost
)

-- 3) Final query: Combines all product results into one output
SELECT 
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    last_sale_date,
    DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency_in_months,
    CASE
        WHEN total_sales > 50000 THEN 'High-Performer'
        WHEN total_sales >= 10000 THEN 'Mid-Range'
        ELSE 'Low-Performer'
    END AS product_segment,
    lifespan,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,
    -- Average Order Revenue (AOR)
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_revenue,
    -- Average Monthly Revenue
    CASE 
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS avg_monthly_revenue
FROM product_aggregations;
