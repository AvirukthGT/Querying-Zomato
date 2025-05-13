-- ======================================
-- View Tables and Check for Missing Data
-- ======================================

SELECT * FROM customer;
SELECT * FROM resturant;
SELECT * FROM orders;
SELECT * FROM rider;
SELECT * FROM delivery;

-- Count total rows and check for NULLs
SELECT count(*) FROM customer;
SELECT * FROM customer
WHERE customer_id IS NULL OR customer_name IS NULL OR reg_date IS NULL;

SELECT count(*) FROM resturant;
SELECT * FROM resturant
WHERE restaurant_id IS NULL OR restaurant_name IS NULL OR city IS NULL OR opening_hours IS NULL;

SELECT count(*) FROM orders;
SELECT * FROM orders
WHERE order_id IS NULL OR order_item IS NULL OR order_date IS NULL OR order_time IS NULL OR order_status IS NULL OR total_amount IS NULL;

SELECT count(*) FROM rider;
SELECT count(*) FROM delivery;

-- ======================================
-- 1. Top 5 Most Frequently Ordered Dishes by "Arjun Mehta" in 2023
-- ======================================

SELECT 
    c.customer_name,
    o.order_item,
    COUNT(*) AS total_orders
FROM customer c
JOIN orders o USING (customer_id)
WHERE c.customer_name ILIKE 'Arjun Mehta'
  AND EXTRACT(YEAR FROM o.order_date) = 2023
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 5;

-- ======================================
-- 2. Popular Time Slots (2-hour intervals)
-- ======================================

-- Approach 1: CASE statement for specific slots
SELECT 
    CASE 
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 0 AND 1 THEN '12AM-2AM'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 2 AND 3 THEN '2AM-4AM'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 4 AND 5 THEN '4AM-6AM'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 6 AND 7 THEN '6AM-8AM'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 8 AND 9 THEN '8AM-10AM'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 10 AND 11 THEN '10AM-12PM'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 AND 13 THEN '12PM-2PM'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 14 AND 15 THEN '2PM-4PM'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 16 AND 17 THEN '4PM-6PM'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 18 AND 19 THEN '6PM-8PM'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 20 AND 21 THEN '8PM-10PM'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 22 AND 23 THEN '10PM-12AM'
    END AS time_slot,
    COUNT(order_id) AS order_count
FROM orders
GROUP BY time_slot
ORDER BY 2 DESC;

-- Alternate faster approach
SELECT 
    FLOOR(EXTRACT(HOUR FROM order_time) / 2) * 2 AS start_time,
    FLOOR(EXTRACT(HOUR FROM order_time) / 2) * 2 + 2 AS end_time,
    COUNT(*) AS total_orders
FROM orders
GROUP BY 1, 2
ORDER BY 3 DESC;

-- ======================================
-- 3. Order Value Analysis (Customers with >750 Orders)
-- ======================================

SELECT 
    c.customer_name,
    ROUND(AVG(o.total_amount)::NUMERIC, 2) AS aov
FROM customer c
JOIN orders o USING (customer_id)
GROUP BY 1
HAVING COUNT(order_id) > 750;

-- ======================================
-- 4. High-Value Customers (Spent > 100K)
-- ======================================

SELECT 
    c.customer_name,
    ROUND(SUM(o.total_amount)::NUMERIC, 2) AS total_spent
FROM customer c
JOIN orders o USING (customer_id)
GROUP BY 1
HAVING SUM(o.total_amount) > 100000;

-- ======================================
-- 5. Orders Without Delivery
-- ======================================

SELECT 
    r.restaurant_name,
    COUNT(o.order_id) AS num_orders_not_delivered
FROM orders o
LEFT JOIN resturant r USING (restaurant_id)
WHERE o.order_id NOT IN (SELECT order_id FROM delivery)
GROUP BY 1
ORDER BY 2 DESC;

-- ======================================
-- 6. Restaurant Revenue Ranking (by City)
-- ======================================

SELECT 
    r.city,
    r.restaurant_name,
    SUM(o.total_amount) AS total_revenue,
    DENSE_RANK() OVER (PARTITION BY r.city ORDER BY SUM(o.total_amount) DESC) AS rank
FROM orders o
JOIN resturant r USING (restaurant_id)
WHERE EXTRACT(YEAR FROM o.order_date) = 2023
GROUP BY 1, 2
ORDER BY 1, 3 DESC;

-- ======================================
-- 7. Most Popular Dish by City
-- ======================================

WITH cte AS (
    SELECT 
        r.city,
        o.order_item,
        COUNT(o.order_id) AS order_count,
        DENSE_RANK() OVER (PARTITION BY r.city ORDER BY COUNT(o.order_id) DESC) AS rank
    FROM orders o
    JOIN resturant r USING (restaurant_id)
    GROUP BY 1, 2
)
SELECT * FROM cte WHERE rank = 1;

-- ======================================
-- 8. Customer Churn Analysis
-- ======================================

-- Method 1: Using CTEs
WITH t2023 AS (
    SELECT DISTINCT c.customer_id
    FROM customer c
    JOIN orders o USING (customer_id)
    WHERE EXTRACT(YEAR FROM o.order_date) = 2023
), t2024 AS (
    SELECT DISTINCT c.customer_id
    FROM customer c
    JOIN orders o USING (customer_id)
    WHERE EXTRACT(YEAR FROM o.order_date) = 2024
)
SELECT t2023.customer_id
FROM t2023
WHERE customer_id NOT IN (SELECT customer_id FROM t2024);

-- Method 2: Using last order year
SELECT *
FROM (
    SELECT 
        c.customer_id,
        c.customer_name,
        EXTRACT(YEAR FROM MAX(order_date)) AS last_order_year
    FROM customer c
    JOIN orders o USING (customer_id)
    GROUP BY 1, 2
) AS t
WHERE last_order_year = 2023;

-- ======================================
-- 9. Order Cancellation Rate (Year-on-Year)
-- ======================================

WITH t2023 AS (
    SELECT 
        o.restaurant_id,
        r.restaurant_name,
        COUNT(o.order_id) AS total_orders_2023,
        COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered_2023
    FROM orders o
    LEFT JOIN resturant r USING (restaurant_id)
    LEFT JOIN delivery d USING (order_id)
    WHERE EXTRACT(YEAR FROM o.order_date) = 2023
    GROUP BY 1, 2
), t2024 AS (
    SELECT 
        o.restaurant_id,
        r.restaurant_name,
        COUNT(o.order_id) AS total_orders_2024,
        COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered_2024
    FROM orders o
    LEFT JOIN resturant r USING (restaurant_id)
    LEFT JOIN delivery d USING (order_id)
    WHERE EXTRACT(YEAR FROM o.order_date) = 2024
    GROUP BY 1, 2
)
SELECT 
    t2023.restaurant_id,
    t2023.restaurant_name,
    ROUND(not_delivered_2023::NUMERIC / total_orders_2023 * 100, 2) AS cancellation_rate_2023,
    ROUND(not_delivered_2024::NUMERIC / total_orders_2024 * 100, 2) AS cancellation_rate_2024
FROM t2023
FULL OUTER JOIN t2024 USING (restaurant_id, restaurant_name)
ORDER BY cancellation_rate_2023 DESC;

-- ======================================
-- 10. Rider Average Delivery Time
-- ======================================

SELECT 
    r.rider_id,
    r.rider_name,
    AVG(ROUND(EXTRACT(EPOCH FROM (d.delivery_time - o.order_time + CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' ELSE INTERVAL '0 day' END)) / 60, 2)) AS avg_time_minutes
FROM rider r
JOIN delivery d USING (rider_id)
JOIN orders o USING (order_id)
WHERE d.delivery_status ILIKE 'delivered'
GROUP BY 1, 2;

-- ======================================
-- 11. Monthly Restaurant Growth Ratio
-- ======================================

WITH cte AS (
    SELECT 
        r.restaurant_id,
        r.restaurant_name,
        TO_CHAR(o.order_date, 'MM-YY') AS month,
        COUNT(o.order_id) AS current_month_count,
        LAG(COUNT(o.order_id)) OVER (PARTITION BY r.restaurant_id ORDER BY TO_CHAR(o.order_date, 'MM-YY')) AS prev_month_count
    FROM resturant r
    JOIN orders o USING (restaurant_id)
    JOIN delivery d USING (order_id)
    WHERE d.delivery_status ILIKE 'delivered'
    GROUP BY 1, 2, 3
)
SELECT *,
    ROUND((current_month_count::NUMERIC - prev_month_count::NUMERIC) / prev_month_count::NUMERIC, 2) AS growth_ratio
FROM cte;

-- ======================================
-- 12. Customer Segmentation (Gold vs Silver)
-- ======================================

WITH cte AS (
    SELECT 
        customer_id,
        SUM(total_amount) AS total_spent,
        COUNT(order_id) AS order_count,
        CASE 
            WHEN SUM(total_amount) > (SELECT AVG(total_amount) FROM orders) THEN 'Gold'
            ELSE 'Silver'
        END AS customer_category
    FROM orders
    GROUP BY 1
)
SELECT customer_category,
    SUM(order_count) AS total_orders,
    SUM(total_spent) AS total_revenue
FROM cte
GROUP BY 1;

-- ======================================
-- 13. Rider Monthly Earnings (8% per delivery)
-- ======================================

SELECT 
    r.rider_id,
    r.rider_name,
    TO_CHAR(o.order_date, 'MM-YY') AS month,
    ROUND(SUM(o.total_amount * 0.08)::NUMERIC, 2) AS total_earnings
FROM orders o
JOIN delivery d USING (order_id)
JOIN rider r USING (rider_id)
GROUP BY 1, 2, 3
ORDER BY 1, 3;

-- ======================================
-- 14. Rider Rating Based on Delivery Time
-- ======================================

WITH cte AS (
    SELECT 
        o.order_id,
        r.rider_id,
        r.rider_name,
        ROUND(EXTRACT(EPOCH FROM (d.delivery_time - o.order_time + CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' ELSE INTERVAL '0 day' END)) / 60, 2) AS time_minutes
    FROM rider r
    JOIN delivery d USING (rider_id)
    JOIN orders o USING (order_id)
    WHERE d.delivery_status ILIKE 'delivered'
)
SELECT rider_id,
    CASE
        WHEN time_minutes < 25 THEN '5 Star'
        WHEN time_minutes BETWEEN 25 AND 40 THEN '4 Star'
        ELSE '3 Star'
    END AS rider_rating,
    COUNT(*)
FROM cte
GROUP BY 1, 2
ORDER BY 1, 2;

-- ======================================
-- 15. Peak Order Day by Restaurant
-- ======================================

WITH cte AS (
    SELECT 
        r.restaurant_name,
        TO_CHAR(o.order_date, 'Day') AS day,
        COUNT(o.order_id) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY r.restaurant_name ORDER BY COUNT(o.order_id) DESC) AS rank
    FROM orders o
    JOIN resturant r USING (restaurant_id)
    GROUP BY 1, 2
)
SELECT restaurant_name, day, total_orders
FROM cte
WHERE rank = 1;

-- ======================================
-- 16. Customer Lifetime Value (CLV)
-- ======================================

SELECT 
    c.customer_id,
    c.customer_name,
    SUM(o.total_amount) AS CLV
FROM orders o
JOIN customer c USING (customer_id)
GROUP BY 1, 2
ORDER BY 1;

-- ======================================
-- 17. Monthly Sales Trends
-- ======================================

WITH cte AS (
    SELECT 
        EXTRACT(YEAR FROM order_date) AS year,
        EXTRACT(MONTH FROM order_date) AS month,
        SUM(total_amount) AS current_month,
        LAG(SUM(total_amount)) OVER (ORDER BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)) AS previous_month
    FROM orders
    GROUP BY 1, 2
)
SELECT *, 
    ROUND((current_month - previous_month)::NUMERIC / previous_month::NUMERIC * 100, 2) AS growth_rate_percentage
FROM cte;

-- ======================================
-- 18. Rider Efficiency
-- ======================================

WITH cte AS (
    SELECT 
        r.rider_id,
        r.rider_name,
        ROUND(EXTRACT(EPOCH FROM (d.delivery_time - o.order_time + CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' ELSE INTERVAL '0 day' END)) / 60, 2) AS time_minutes
    FROM orders o
    JOIN delivery d USING (order_id)
    JOIN rider r USING (rider_id)
    WHERE d.delivery_status ILIKE 'delivered'
)
SELECT MIN(avg_time_minutes), MAX(avg_time_minutes)
FROM (
    SELECT rider_id, rider_name, AVG(time_minutes) AS avg_time_minutes
    FROM cte
    GROUP BY 1, 2
) rider_avg_times;

-- ======================================
-- 19. Top 3 Popular Dishes per Season
-- ======================================

WITH cte AS (
    SELECT 
        o.order_item,
        CASE 
            WHEN EXTRACT(MONTH FROM o.order_date) BETWEEN 1 AND 3 THEN 'Spring'
            WHEN EXTRACT(MONTH FROM o.order_date) BETWEEN 4 AND 6 THEN 'Summer'
            WHEN EXTRACT(MONTH FROM o.order_date) BETWEEN 7 AND 9 THEN 'Autumn'
            WHEN EXTRACT(MONTH FROM o.order_date) BETWEEN 10 AND 12 THEN 'Winter'
        END AS season
    FROM orders o
),
ranked_items AS (
    SELECT 
        season,
        order_item,
        COUNT(*) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY season ORDER BY COUNT(*) DESC) AS rank
    FROM cte
    GROUP BY 1, 2
)
SELECT season, order_item, total_orders
FROM ranked_items
WHERE rank <= 3;

-- Q20. City Revenue Ranking

-- Rank each city based on the total revenue for the last year (2023).


select r.city,sum(o.total_amount) as total_revenue ,rank() over(order by sum(o.total_amount)) from resturant r join orders o using(restaurant_id)
where extract(year from o.order_date)=2023
group by 1

-- ======================================
-- Q20. City Revenue Ranking
-- ======================================


SELECT 
    r.city,
    SUM(o.total_amount) AS total_revenue,
    RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS city_rank
FROM resturant r
JOIN orders o USING (restaurant_id)
WHERE EXTRACT(YEAR FROM o.order_date) = 2023
GROUP BY r.city
ORDER BY total_revenue DESC;

