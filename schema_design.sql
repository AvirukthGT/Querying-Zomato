-- -----------------------------------------
-- ZOMATO SALES DATABASE SCHEMA
-- -----------------------------------------

-- Drop existing tables if they exist to start fresh
DROP TABLE IF EXISTS delivery;
DROP TABLE IF EXISTS rider;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS resturant;
DROP TABLE IF EXISTS customer;

-- -----------------------------------------
-- CUSTOMER TABLE
-- Stores customer details
-- -----------------------------------------
CREATE TABLE customer (
    customer_id INT PRIMARY KEY,            -- Unique customer ID
    customer_name VARCHAR(30),               -- Name of the customer
    reg_date DATE                            -- Registration date
);

-- -----------------------------------------
-- RESTAURANT TABLE
-- Stores restaurant details
-- -----------------------------------------
CREATE TABLE resturant (
    restaurant_id INT PRIMARY KEY,           -- Unique restaurant ID
    restaurant_name VARCHAR(55),              -- Name of the restaurant
    city VARCHAR(15),                         -- City where the restaurant is located
    opening_hours VARCHAR(55)                 -- Opening hours (text format)
);

-- -----------------------------------------
-- ORDERS TABLE
-- Stores orders placed by customers
-- -----------------------------------------
CREATE TABLE orders (
    order_id INT PRIMARY KEY,                 -- Unique order ID
    customer_id INT,                          -- Customer who placed the order
    restaurant_id INT,                        -- Restaurant from where the order is placed
    order_item VARCHAR(30),                   -- Item ordered
    order_date DATE,                          -- Date of the order
    order_time TIME,                          -- Time of the order
    order_status VARCHAR(25),                 -- Status (e.g., Delivered, Cancelled)
    total_amount FLOAT,                       -- Total order amount
    -- Foreign keys
    CONSTRAINT fk_customers_order FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    CONSTRAINT fk_resturant_order FOREIGN KEY (restaurant_id) REFERENCES resturant(restaurant_id)
);

-- -----------------------------------------
-- RIDER TABLE
-- Stores delivery rider details
-- -----------------------------------------
CREATE TABLE rider (
    rider_id INT PRIMARY KEY,                 -- Unique rider ID
    rider_name VARCHAR(55),                   -- Name of the rider
    sign_up DATE                               -- Date when the rider signed up
);

-- -----------------------------------------
-- DELIVERY TABLE
-- Stores delivery details
-- -----------------------------------------
CREATE TABLE delivery (
    delivery_id INT PRIMARY KEY,              -- Unique delivery ID
    order_id INT,                             -- Associated order
    delivery_status VARCHAR(35),              -- Status of delivery (e.g., On the way, Delivered)
    delivery_time TIME,                       -- Time of delivery
    rider_id INT,                             -- Rider who delivered the order
    -- Foreign keys
    CONSTRAINT fk_order_delivery FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT fk_rider_delivery FOREIGN KEY (rider_id) REFERENCES rider(rider_id)
);
