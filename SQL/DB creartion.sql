CREATE DATABASE bapcor_bi;
USE bapcor_bi;

CREATE TABLE dim_stores(
	store_id INT PRIMARY KEY,
    store_name VARCHAR(100),
    brand VARCHAR(50),
    region VARCHAR(50),
    channel VARCHAR(30)
);

CREATE TABLE dim_products(
	product_id INT PRIMARY KEY,
    product_name VARCHAR(200),
    category VARCHAR(50),
    unit_cost DECIMAL(10,2),
    unit_price DECIMAL(10,2),
    reorder_level INT
);

CREATE TABLE dim_customers(
	customer_id INT PRIMARY KEY,
    customer_name VARCHAR(200),
    channel VARCHAR(50),
    region VARCHAR(50),
    account_status ENUM('Active','Inactive','OnHold'),
    credit_limit DECIMAL(10,2),
    email VARCHAR(200)
);

CREATE TABLE dim_dates(
	date_id DATE PRIMARY KEY,
    year INT,
    quarter INT,
    month INT,
    month_name VARCHAR(20),
    day_of_week VARCHAR(20)
);

CREATE TABLE fact_orders(
	order_id INT PRIMARY KEY,
    order_date DATE,
    store_id INT,
    product_id INT,
    customer_id INT,
    quantity INT,
    unit_price DECIMAL(10,2),
    discount_pct DECIMAL(4,2),
    total_amount DECIMAL(10,2),
    FOREIGN KEY (order_date) REFERENCES dim_dates(date_id), 
    FOREIGN KEY (store_id) REFERENCES dim_stores(store_id), 
    FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id)
);

CREATE TABLE fact_inventory(
	inventory_id INT PRIMARY KEY,
    snapshot_date DATE,
    store_id INT,
    product_id INT,
    quantity_on_hand INT,
    quantity_on_order INT,
    FOREIGN KEY (store_id) REFERENCES dim_stores(store_id), 
    FOREIGN KEY (product_id) REFERENCES dim_products(product_id)
);
select * from dim_stores;

SELECT * FROM dim_products LIMIT 5;

SELECT * FROM dim_customers  LIMIT 5;

SELECT COUNT(*) FROM dim_dates;
SELECT * FROM dim_dates WHERE date_id = '2025-01-01';
SELECT * FROM dim_dates ORDER BY date_id DESC LIMIT 1;

SELECT COUNT(*) FROM fact_orders;
SELECT * FROM fact_orders LIMIT 5;

SELECT COUNT(*) FROM fact_orders WHERE product_id = 9999;
SELECT COUNT(*) FROM fact_orders WHERE total_amount IS NULL;

SELECT COUNT(DISTINCT snapshot_date) FROM fact_inventory;
SELECT COUNT(*) FROM fact_inventory WHERE quantity_on_hand < 15 AND quantity_on_order = 0;
SELECT channel, COUNT(*) FROM dim_stores GROUP BY channel;
SHOW TABLES;
