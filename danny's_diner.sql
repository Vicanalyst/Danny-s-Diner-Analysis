/*-------------------------------------------------------
 In this project, I am analysing the dataset for danny's_diner
containing three tables; sales, menu, and members. 
The following questions are to be answered:

1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item from the menu purchased by each customer?
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
5. Which item was the most popular for each customer?
6. Which item was purchased first by the customer after they became a member?
7. Which item was purchased just before the customer became a member?
8. What is the total items and amount spent for each member before they became a member?
9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
not just sushi - how many points do customer A and B have at the end of January?
-------------------------------------------------------------------------------- */

CREATE SCHEMA IF NOT EXISTS dannys_diner;
use dannys_diner;
CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
-- What is the total amount each customer spent at the restaurant?

SELECT 
    s.customer_id, SUM(m.price) AS amount_spent
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
GROUP BY 1;

-- How many days has each customer visited the restaurant?

SELECT 
    customer_id, COUNT(*) AS days_visited
FROM
    sales
GROUP BY 1;

-- What was the first item from the menu purchased by each customer?
WITH CTE AS (
SELECT 
       customer_id,
	   product_id,
       row_number() OVER (partition by customer_id order by order_date) AS row_num
FROM sales
) # creating a cross table expression (CTE)

SELECT
       c.customer_id,
       c.product_id,
       m.product_name
FROM CTE c
JOIN menu m -- joining menu table to get the 'product_name' column
ON c.product_id = m.product_id
WHERE c.row_num = 1
GROUP BY 1;

-- What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
    s.product_id,
    m.product_name,
    COUNT(*) AS number_of_times_purchased
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 3 DESC;

-- Which item was the most popular for each customer?

/* The aim is to reveal the items that are bought many times by each customer. 
The window function 'DENSE_RANK' is used to rank the count of products bought in descending order,
partioning by customer_id */

WITH popular_items AS (
SELECT 
    s.customer_id,
    s.product_id,
    m.product_name,
    COUNT(*) AS number_of_times_purchased,
    DENSE_RANK() OVER (partition by customer_id ORDER BY count(*) DESC) AS drnk
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
    GROUP BY 1,2)
    
    SELECT customer_id, product_name
    FROM popular_items
    WHERE drnk = 1;
    
    -- Which item was purchased first by the customer after they became a member?
    
   WITH first_item AS(
   SELECT 
		 s.customer_id,
         m.product_name,
         s.order_date,
         Row_number () OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS row_num
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
        JOIN
    members me ON s.customer_id = me.customer_id
    WHERE s.order_date >= me.join_date)
    
    SELECT customer_id, product_name
    FROM first_item
    WHERE row_num = 1;

-- Which item was purchased just before the customer became a member?

   WITH first_item AS(
   SELECT 
		 s.customer_id,
         m.product_name,
         s.order_date,
         Row_number () OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS row_num
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
        JOIN
    members me ON s.customer_id = me.customer_id
    WHERE s.order_date < me.join_date)
    
    SELECT customer_id, product_name
    FROM first_item
    WHERE row_num = 1;

-- What is the total items and amount spent for each member before they became a member?

SELECT 
    s.customer_id,
    COUNT(s.product_id) AS total_items,
    SUM(m.price) AS amount_spent
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
        JOIN
    members me ON s.customer_id = me.customer_id
WHERE
    s.order_date < me.join_date
GROUP BY 1;

-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH customer_points AS (
SELECT 
	  s.customer_id,
      s.product_id,
      m.product_name,
      m.price,
      CASE WHEN m.product_name = 'sushi' THEN (m.price *10*2)
      ELSE (m.price *10)
      END AS points
FROM sales s
JOIN menu m on s.product_id = m.product_id
)

SELECT
      customer_id,
      sum(points) AS total_points
FROM customer_points
GROUP BY 1;

/* In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
not just sushi - how many points do customer A and B have at the end of January? */

SELECT 
    s.customer_id, SUM(m.price * 10 * 2) AS points
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
        JOIN
    members me ON s.customer_id = me.customer_id
WHERE
    s.order_date >= me.join_date
GROUP BY 1;
      



          

