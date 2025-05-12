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






