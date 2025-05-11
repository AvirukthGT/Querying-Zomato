--Zomato sales
--schema
drop table if exists customer;
create table customer(
	customer_id int primary key,	
	customer_name varchar(30),	
	reg_date date

);

drop table if exists resturant;
create table resturant(
	restaurant_id int primary key,	
	restaurant_name varchar(55),
	city varchar(15),
	opening_hours varchar(55)

);

drop table if exists orders;
create table orders(
	order_id	int primary key,
	customer_id	 int,
	restaurant_id	int,
	order_item	varchar(30),
	order_date	date,
	order_time	time,
	order_status varchar(25),	
	total_amount float
	

);
alter table orders add constraint fk_customers_order foreign key (customer_id) references customer(customer_id);
alter table orders add constraint fk_resturant_order foreign key (restaurant_id) references resturant(restaurant_id);



drop table if exists rider;
create table rider(
	rider_id int primary key,	
	rider_name varchar(55),	
	sign_up date

);

drop table if exists delivery;
create table delivery(
	delivery_id int primary key,	
	order_id int,	
	delivery_status varchar(35),	
	delivery_time time,	
	rider_id int,
	constraint fk_order_delivery foreign key(order_id) references orders(order_id),
	constraint fk_rider_delivery foreign key(rider_id) references rider(rider_id)

);