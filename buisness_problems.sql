--Data analysis

select * from customer;
select * from resturant;
select * from orders;
select * from rider;
select * from delivery;


select count(*) from customer;
select * from customer
where customer_id is null or customer_name is null or reg_date is null;

select count(*) from resturant;
select * from resturant
where restaurant_id is null or restaurant_name is null or city is null or opening_hours is null;

select count(*) from orders;
select * from orders
where order_id is null or order_item is null or order_date is null or order_time is null or order_status is null or total_amount is null;

select count(*) from rider;
select count(*) from delivery;


--Top 5 Most Frequently Ordered Dishes by the customer "Arjun Mehta" in 2023

select c.customer_name,order_item,count(*) as total_orders from customer c join orders o using (customer_id)
where c.customer_name ilike 'Arjun Mehta' and extract(year from o.order_date)=2023
group by 1,2
order by 3 desc
limit 5;


--Popular Time Slots
--Identify the time slots with the most order placements, based on 2-hour intervals.
select 
	case 
		when extract(hour from order_time) between 0 and 1 then '12AM-2AM'
		when extract(hour from order_time) between 2 and 3 then '2AM-4AM'
		when extract(hour from order_time) between 4 and 5 then '4AM-6AM'
		when extract(hour from order_time) between 6 and 7 then '6AM-8AM'
		when extract(hour from order_time) between 8 and 9 then '8AM-10AM'
		when extract(hour from order_time) between 10 and 11 then '10AM-12PM'
		when extract(hour from order_time) between 12 and 13 then '12PM-2PM'
		when extract(hour from order_time) between 14 and 15 then '2PM-4PM'
		when extract(hour from order_time) between 16 and 17 then '4PM-6PM'
		when extract(hour from order_time) between 18 and 19 then '6PM-8PM'
		when extract(hour from order_time) between 20 and 21 then '8PM-10PM'
		when extract(hour from order_time) between 22 and 23 then '10MM-12PM'
	 end as time_slot,
	 count(order_id) as order_count
	
from orders
group by time_slot
order by 2 desc;

--Alternate approach since the prev query takes too much time

SELECT 
	FLOOR(EXTRACT(HOUR FROM order_time)/2)*2 as start_time,
	FLOOR(EXTRACT(HOUR FROM order_time)/2)*2 + 2 as end_time,
	COUNT(*) as total_orders
FROM orders
GROUP BY 1, 2
ORDER BY 3 DESC


--Order Value Analysis
--Find the average order value (AOV) per customer who has placed more than 750 orders.

select c.customer_name,round(avg(o.total_amount)::numeric,2) as aov from customer c join orders o using(customer_id)
group by 1 
having count(order_id)>750

-- High-Value Customers
-- List the customers who have spent more than 100K in total on food orders.

select c.customer_name,round(sum(o.total_amount)::numeric,2) as total_spent from customer c join orders o using(customer_id)
group by 1 
having sum(o.total_amount)>100000

--Orders Without Delivery
--find orders that were placed but not delivered.

select r.restaurant_name,count(o.order_id) as num_orders_not_delivered from orders o left  join resturant r  using(restaurant_id)
where o.order_id not in (select order_id from delivery)
group by 1
order by 2 desc

--Restaurant Revenue Ranking
-- Rank restaurants by their total revenue from the last year.
-- Return: restaurant_name, total_revenue, and their rank within their city.

select r.city,r.restaurant_name,sum(o.total_amount) as total_revenue,
dense_rank() over(partition by r.city order by sum(o.total_amount) desc) as rank
from orders o join resturant r  using(restaurant_id)
where extract(year from o.order_date)=2023
group by 1,2
order by 1,3 desc

-- Most Popular Dish by City
with cte as (
select r.city,o.order_item,count(o.order_id),
dense_rank() over(partition by r.city order by count(o.order_id) desc) as rank
from  orders o join resturant r  using(restaurant_id)
group by 1,2
order by 1,3 desc
) select * from cte where rank=1

-- Customer Churn
-- Find customers who haven’t placed an order in 2024 but did in 2023.

with t2023 as (
select c.customer_id,c.customer_name
from customer c join orders o using(customer_id)
where extract(year from o.order_date)=2023
), t2024 as 
(select c.customer_id,c.customer_name
from customer c join orders o using(customer_id)
where extract(year from o.order_date)=2024)
select distinct customer_id, customer_name from t2023 where customer_id not in (select customer_id from t2024)


--alternate method
select * from (
select c.customer_id,c.customer_name,extract(year from max(order_date)) as last_order
from customer c join orders o using(customer_id) 
group by 1,2
) as t where last_order=2023

-- Calculating and comparing the order cancellation rate for each restaurant between the current year
-- and the previous year.
with t2023 as (
select o.restaurant_id,r.restaurant_name,count(o.order_id) as total_orders_2023,COunt(case when d.delivery_id is null then 1 end) as not_delivered_2023 from orders o left join resturant r  using(restaurant_id) left join delivery d using(order_id)
where extract(year from o.order_date)=2023
group by 1,2
), t2024 as (
	select o.restaurant_id,r.restaurant_name,count(o.order_id) as total_orders_2024,COunt(case when d.delivery_id is null then 1 end) as not_delivered_2024 from orders o left join resturant r  using(restaurant_id) left join delivery d using(order_id)
where extract(year from o.order_date)=2024
group by 1,2
) select t2023.restaurant_id,t2023.restaurant_name,round(not_delivered_2023::numeric/total_orders_2023*100,2) as cancellation_rate_2023,
	round(not_delivered_2024::numeric/total_orders_2024*100,2) as cancellation_rate_2024
from t2023   full outer join t2024  using(restaurant_id,restaurant_name) order by not_delivered_2023 desc


 -- Rider Average Delivery Time

 select r.rider_id,r.rider_name,
 avg(round(extract(epoch from (d.delivery_time-o.order_time + case when d.delivery_time < o.order_time then interval '1 days' else interval '0 days' end))/60,2)) as avg_time_minues
 	
 
 from rider r join delivery d using(rider_id) join orders o using(order_id)
 where d.delivery_status ilike 'delivered'
 group by 1,2;

-- Monthly Restaurant Growth Ratio
-- Calculate each restaurant's growth ratio based on the total number of delivered orders since its
-- joining.
with cte as 
(select 
	r.restaurant_id,
	r.restaurant_name,
	to_char(o.order_date,'mm-yy') as month,
	count(o.order_id) as current_month_count,
	lag(count(o.order_id),1) over(partition by r.restaurant_id) as prev_month_count

from resturant r join orders o using (restaurant_id) join delivery d using(order_id)
where d.delivery_status ilike 'delivered'         
group by 1,2,3
order by 1,3
) select *, round((current_month_count::numeric-prev_month_count::numeric)/prev_month_count::numeric,2) as growth_ratio from cte


-- Customer Segmentation
-- Segmentation of  customers into 'Gold' or 'Silver' groups based on their total spending compared to the
-- average order value (AOV). If a customer's total spending exceeds the AOV, labelling them as
-- 'Gold'; otherwise, labelling them as 'Silver'.
-- Return: The total number of orders and total revenue for each segment.

with cte as (
select 
	customer_id,
	sum(total_amount) as total_spent ,
	count(order_id) as order_count ,
	case 
		when sum(total_amount) > (select avg(total_amount) from orders )then 'Gold' 
		else 'Silver'
	end as customer_category
from orders 
group by 1
) select customer_category,sum(order_count) as total_orders, sum(total_spent) as total_revenue from cte
group by 1

--  Rider Monthly Earnings

-- Calculating each rider's total monthly earnings, assuming they earn 8% of the order amount.

select r.rider_id,r.rider_name,to_char(o.order_date,'mm-yy') as month,round(sum(o.total_amount*0.08)::numeric,2) as total_earnings from orders o join delivery d using(order_id) join rider r using(rider_id)
group by 1,2,3
order by 1,3


-- Finding the number of 5-star, 4-star, and 3-star ratings each rider has.
-- Riders receive ratings based on delivery time:
-- ● 5-star: Delivered in less than 25 minutes
-- ● 4-star: Delivered between 25 and 40 minutes
-- ● 3-star: Delivered after 40 minutes

select rider_id,rider_rating,count(*) from (
with cte as ( 
select o.order_id,r.rider_id,r.rider_name,
  round(extract(epoch from (d.delivery_time-o.order_time + case when d.delivery_time < o.order_time then interval '1 day' else interval '0 day' end))/60,2) as time_minutes
  from rider r join delivery d using(rider_id) join orders o using(order_id)
 where d.delivery_status ilike 'delivered'
)
select *, case
	when time_minutes <25 then '5 Star'
	when time_minutes between 25 and 40 then '4 Star'
	else '3 Star' end as rider_rating 
	from cte
) as t group by 1,2
order by 1,2

-- Order Frequency by Day
-- Analyzing order frequency per day of the week and identify the peak day for each restaurant.
with cte as(
select r.restaurant_name,to_char(o.order_date,'Day') as day,count(o.order_id),
dense_rank() over(partition by r.restaurant_name order by count(o.order_id) desc ) as rank
from orders o join resturant r using (restaurant_id)
group by 1,2
order by 1,3 
) select restaurant_name,day,count as total_orders from cte where rank=1;