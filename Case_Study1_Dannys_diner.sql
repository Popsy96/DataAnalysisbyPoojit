CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
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
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
select * from members
select * from menu
select * from sales

/* -------------------- Case Study Questions --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

		SELECT s.customer_id, SUM(m.price) as Total_Spend 
		FROM Sales s
		INNER JOIN menu m ON s.product_id = m.product_id
		GROUP BY s.customer_id
		ORDER BY s.customer_id

-- 2. How many days has each customer visited the restaurant?

		SELECT customer_id, COUNT(DISTINCT order_date) as days_visited
		FROM Sales 
		GROUP BY customer_id
		
-- 3. What was the first item from the menu purchased by each customer?
		
		WITH CTE AS 
		(
			SELECT customer_id, order_date, product_name,
			DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date ASC) as item
			FROM sales s
			INNER JOIN menu m ON s.product_id = m.product_id
		)
		SELECT customer_id, product_name
		FROM CTE
		WHERE item = 1
		GROUP BY customer_id, product_name


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

		SELECT product_name, COUNT(order_date) as orders 
		FROM sales s
		INNER JOIN menu m ON s.product_id = m.product_id
		GROUP BY product_name
		ORDER BY orders DESC
		LIMIT 1
				
-- 5. Which item was the most popular for each customer?

		WITH CTE AS
		(
			SELECT customer_id, product_name, COUNT(order_date) as orders,
			DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(order_date) DESC) as popularity
			FROM sales s
			INNER JOIN menu m ON s.product_id = m.product_id
			GROUP BY customer_id, product_name	
		)
		SELECT customer_id, product_name, orders
		FROM CTE
		WHERE popularity = 1


-- 6. Which item was purchased first by the customer after they became a member?

 		WITH CTE AS
		(
			SELECT s.customer_id, order_date, join_date, product_name,
			ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY order_date) as rnk
			FROM sales s
			INNER JOIN members mem ON mem.customer_id = s.customer_id
			INNER JOIN menu m ON s.product_id = m.product_id
			WHERE order_date > join_date
		)
		SELECT customer_id, product_name
		FROM CTE
		WHERE rnk =1 

-- 7. Which item was purchased just before the customer became a member?

 		WITH CTE AS
		(
			SELECT s.customer_id, order_date, join_date, product_name,
			ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY order_date) as rnk
			FROM sales s
			INNER JOIN members mem ON mem.customer_id = s.customer_id
			INNER JOIN menu m ON s.product_id = m.product_id
			WHERE order_date < join_date
		)
		SELECT customer_id, product_name
		FROM CTE
		WHERE rnk =1


-- 8. What is the total items and amount spent for each member before they became a member?

 		SELECT s.customer_id, COUNT(product_name) AS total_items,SUM(price) AS total_spent
		FROM sales s
		INNER JOIN members mem ON mem.customer_id = s.customer_id
		INNER JOIN menu m ON s.product_id = m.product_id
		WHERE order_date < join_date
		GROUP BY s.customer_id
		ORDER BY s.customer_id


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier
-- 	   how many points would each customer have?
		
		SELECT customer_id,
		SUM(CASE
				WHEN product_name = 'sushi' THEN price * 10 * 2
				ELSE price * 10
				END) as points
		FROM menu m 
		INNER JOIN sales s ON s.product_id = m.product_id
		GROUP BY customer_id
		ORDER BY customer_id
		
-- 10. In the first week after a customer joins the program (including their join date) 
	-- they earn 2x points on all items, not just sushi 
	-- how many points do customer A and B have at the end of January?
				
		SELECT 
		  s.customer_id, 
		  SUM(
			CASE 
			  WHEN s.order_date BETWEEN mem.join_date AND (mem.join_date + INTERVAL '6 days') THEN price * 10 * 2 
			  WHEN product_name = 'sushi' THEN price * 10 * 2 
			  ELSE price * 10 
			END
		  ) as points 
		FROM MENU as m
		INNER JOIN sales as s ON s.product_id = m.product_id
		INNER JOIN members AS mem ON mem.customer_id = s.customer_id 
		WHERE DATE_TRUNC('month', s.order_date) = DATE '2021-01-01' 
		GROUP BY  s.customer_id
		ORDER BY S.customer_id

/* -------------------- Bonus Questions --------------------*/

--Join all things

		SELECT s.customer_id, order_date, product_name, price,
		CASE 
		WHEN join_date IS NULL THEN 'N'
		WHEN order_date < join_date THEN 'N'
		ELSE 'Y'
		END as member
		FROM sales s 
		INNER JOIN menu m on m.product_id = s.product_id
		LEFT JOIN members AS mem ON mem.customer_id = s.customer_id
		ORDER BY s.customer_id, order_date, pric
-- RANK
		WITH CTE AS 
		(
			SELECT s.customer_id, order_date, product_name, price,
			CASE 
			WHEN join_date IS NULL THEN 'N'
			WHEN order_date < join_date THEN 'N'
			ELSE 'Y'
			END as member
			FROM sales s 
			INNER JOIN menu m on m.product_id = s.product_id
			LEFT JOIN members AS mem ON mem.customer_id = s.customer_id
			ORDER BY s.customer_id, order_date, price DESC
		)

		SELECT *,
		CASE 
		WHEN member ='N' THEN NULL
		ELSE RANK() OVER(PARTITION BY customer_id,member ORDER BY order_date)
		END as Rnk
		FROM CTE 











		