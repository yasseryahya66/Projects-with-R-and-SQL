-- let's view the tables of the northwind database
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

-- Combine orders and customers tables to get more detailed information about each order

SELECT o.*, c.* 
  FROM orders AS o
INNER JOIN customers AS c
ON o.customer_id = c.customer_id

-- Combine order_details, products, and orders tables to get detailed order 
-- information, including the product name and quantity.

SELECT p.*, od.*, o.*
  FROM products AS p
INNER JOIN order_details AS od
ON od.product_id = p.product_id
INNER JOIN orders As o
ON od.order_id = o.order_id

-- Combine employees and orders tables to see who is responsible for each order.

SELECT e.*, o.*
  FROM employees AS e
INNER JOIN orders AS o
ON o.employee_id = e.employee_id

             -- Ranking Employee Sales Performance --
-- 1- Create a CTE that calculates the total sales for each employee.
-- 2- Use the RANK function with an OVER clause in the main query to assign a 
   -- rank to each employee based on their total sales. 
   
With four_tables AS
(
SELECT od.unit_price AS unit_price,
	   od.quantity AS quantity,
	   e.first_name AS first_name,
	   e.last_name AS last_name
  FROM products AS p
INNER JOIN order_details AS od
ON od.product_id = p.product_id
INNER JOIN orders As o
ON od.order_id = o.order_id
INNER JOIN employees AS e
On o.employee_id = e.employee_id
),
 total_sales_table AS
(
SELECT f.first_name AS first_name,
       f.last_name AS last_name,
	   SUM(f.unit_price * f.quantity) AS total_sales
  FROM four_tables AS f
  GROUP BY first_name, last_name
)
SELECT  first_name || ' ' || last_name AS employee_name, 
		total_sales,
		DENSE_RANK() OVER(order by total_sales desc) AS sales_rank
   FROM total_sales_table;
-- While Margeret Peacock is the highest sales performer, steven Buchanan is the loswest


                  -- Running Total of Monthly Sales --
-- 1- Join the Orders and Order_Details tables to bring together the data you need.
-- 2- Group by the month of the Order_Date and calculate the total sales for each month.
     -- Use the DATE_TRUNC function to truncate the Order_Date to the nearest month
-- 3- Use the SUM function with an OVER clause to calculate the running total of sales by month.

WITH two_tables AS
(
SELECT DATE_TRUNC('month', o.order_date)::DATE as "month",
       SUM(od.unit_price * od.quantity * (1 - Discount)) AS total_sales
  FROM orders AS o
  INNER JOIN order_details AS od
  ON o.order_id = od.order_id
  GROUP BY DATE_TRUNC('month', o.order_date)
 
)
SELECT "month", total_sales,
       SUM(total_sales) OVER(ORDER BY "month") AS running_total
  FROM two_tables
  ORDER BY "month"
  

                 -- Month-Over-Month Sales Growth --
-- 1- Create a CTE that calculates the total sales for each month.
-- 2- Create a second CTE that uses the LAG function with an OVER clause to get 
    -- the total sales of the previous month.
-- 3- In your main query, calculate the month-over-month sales growth rate.


WITH two_tables_total_sales AS
(
SELECT DATE_TRUNC('month', o.order_date)::DATE as "month",
       SUM(od.unit_price * od.quantity * (1 - Discount)) AS total_sales
  FROM orders AS o
  INNER JOIN order_details AS od
  ON o.order_id = od.order_id
  GROUP BY DATE_TRUNC('month', o.order_date)
),
previous_month_total_sales_table AS
(
SELECT "month",
	    total_sales,
       LAG(total_sales) OVER(ORDER BY "month") AS previous_month_total_sales
  FROM two_tables_total_sales
)
SELECT "month",
        total_sales,
       previous_month_total_sales,
	   ((total_sales - previous_month_total_sales) / previous_month_total_sales *100) as growth_rate
  From previous_month_total_sales_table;
  

                 -- Identifying High-Value Customers --
-- 1- Create a CTE that includes customer identification and calculates 
-- the value of each of their orders.
-- 2- In the main query use the CTE to categorize each order as 'Above Average' 
--  or 'Average/Below Average' using a CASE statement.
-- As an extension, try counting how many orders are 'Above Average' for each customer.

With two_tables_orders AS
(
	SELECT o.customer_id AS customer_id,
	       o.order_id AS order_id,
	       SUM(od.quantity * od.unit_price * (1 - od.discount)) AS order_value
	  FROM orders AS o
	INNER JOIN order_details AS od
	ON o.order_id = od.order_id
	GROUP BY o.customer_id, o.order_id
)

SELECT customer_id,
       order_id,
       order_value, 
       AVG(order_value) OVER( ) AS avg_order_value,
	   CASE
	       when order_value > AVG(order_value) OVER( ) THEN 'Above Average'
		   ELSE 'Average/Below Average'
		   END AS order_categorization
  FROM two_tables_orders
  LIMIT 15;
  
-- As an extension, try counting how many orders are 'Above Average' for each customer.

  
  With two_tables_orders AS
(
	SELECT o.customer_id AS customer_id,
	       o.order_id AS order_id,
	       SUM(od.quantity * od.unit_price * (1 - od.discount)) AS order_value
	  FROM orders AS o
	INNER JOIN order_details AS od
	ON o.order_id = od.order_id
	GROUP BY o.customer_id, o.order_id
),
 order_category AS
(
SELECT customer_id,
       order_id,
       order_value, 
       AVG(order_value) OVER( ) AS avg_order_value,
	   CASE
	       when order_value > AVG(order_value) OVER( ) THEN 'Above Average'
		   ELSE 'Average/Below Average'
		   END AS order_categorization
  FROM two_tables_orders
 )
 
SELECT customer_id,
       count(order_categorization) AS orders_numbers
  FROM order_category
  GROUP BY customer_id, order_categorization
 Having order_categorization = 'Above Average'
 ORDER BY orders_numbers DESC;
 
                -- Percentage of Sales for Each Category --
 -- Find the percentage of total sales for each product category.
 -- 1- Create a CTE that calculates the total sales for each product category
 -- 2- Use your CTE in the main query to calculate the percentage of total sales
      -- for each product category.
 With categories_order_details_products_tables AS
( 
SELECT c.category_id AS category_id,
	   c.category_name As category_name,
       SUM(od.unit_price * od.quantity * (1- od.discount)) AS total_sales
  FROM categories AS c
INNER JOIN products AS p
   ON p.category_id = c.category_id
INNER JOIN order_details AS od
	ON od.product_id = p.product_id
	group by c.category_id
   order by c.category_id 
)
SELECT category_id, 
	   category_name,
	   total_sales,
	   total_sales / SUM(total_sales) OVER() * 100 as product_sales_percentage
  FROM categories_order_details_products_tables
   
  
				-- Top Products Per Category --
-- 1- Create a CTE that calculates the total sales for each product.
-- 2- Use the ROW_NUMBER function with an OVER clause in the main query to assign
     -- a row number to each product within each category based on the total sales
-- 3- Use a WHERE clause in the main query to filter out the products that have 
    -- a row number greater than 3.

With categories_order_details_products AS
( 
SELECT p.product_id,
	   p.product_name AS product_name,
	   c.category_name As category_name,
       SUM(p.unit_price * od.quantity * (1- od.discount)) AS total_sales
  FROM categories AS c
INNER JOIN products AS p
   ON p.category_id = c.category_id
INNER JOIN order_details AS od
	ON od.product_id = p.product_id
	group by p.product_id, c.category_name
)
select product_name, 
      category_name,
	  total_sales, 
	  product_ranking
  FROM (SELECT *,
		ROW_NUMBER() OVER(partition by category_name
					    order by total_sales DESC) as product_ranking
        FROM categories_order_details_products)
 Where product_ranking <= 3;
	
--




