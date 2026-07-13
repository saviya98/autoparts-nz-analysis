
CREATE VIEW vw_sales_by_region AS
	SELECT
		COUNT(DISTINCT o.order_id) AS order_count,
        SUM(o.total_amount) AS total_revenue,
        SUM(o.quantity) AS units_sold,
        SUM(o.total_amount)/COUNT(DISTINCT o.order_id) AS average_order_value,
        s.region,
        s.channel,
        s.brand,
        d.year,
        d.month_name
    FROM fact_orders o
    LEFT JOIN dim_stores s ON o.store_id = s.store_id
    LEFT JOIN dim_dates d ON o.order_date = d.date_id 
    WHERE o.total_amount IS NOT NULL
    GROUP BY s.region, s.channel, s.brand, d.year, d.month_name;
    
SELECT * FROM vw_sales_by_region ORDER BY total_revenue DESC LIMIT 10;

CREATE VIEW vw_sales_by_category AS
	SELECT
		COUNT(DISTINCT o.order_id) AS order_count,
        SUM(o.total_amount) AS total_revenue,
        SUM(o.quantity) AS units_sold,
        ROUND(AVG(o.discount_pct*100),1) AS average_discount,
        s.region,
        p.category
    FROM fact_orders o
    LEFT JOIN dim_products p ON o.product_id = p.product_id
    LEFT JOIN dim_stores s ON o.store_id = s.store_id
	WHERE o.total_amount IS NOT NULL
    GROUP BY s.region, p.category;
    
    
SELECT * FROM vw_sales_by_category ORDER BY total_revenue DESC LIMIT 10;

CREATE VIEW vw_low_stock_alerts AS
	SELECT
		p.product_name,
        p.category,
        p.reorder_level,
        s.store_name,
        s.region,
        s.brand,
        (p.reorder_level - i.quantity_on_hand) AS shortfall,
        i.quantity_on_order
    FROM fact_inventory i
    LEFT JOIN dim_products p ON i.product_id = p.product_id
    LEFT JOIN dim_stores s ON i.store_id = s.store_id
    WHERE i.quantity_on_hand < p.reorder_level
    ORDER BY shortfall DESC;
    
SELECT * FROM vw_low_stock_alerts LIMIT 10;
SELECT COUNT(*) FROM vw_low_stock_alerts;

CREATE VIEW vw_customer_account_health AS
	SELECT
		c.customer_id,
        c.customer_name,
        c.channel,
        c.region,
        c.credit_limit,
        c.account_status,
        COALESCE(SUM(o.total_amount),0) AS lifetime_revenue,
        CASE 
			WHEN c.email IS NULL
			THEN 1
			ELSE 0
		END AS missing_email_flag,
        MAX(o.order_date) AS last_order_date
    FROM dim_customers c
    LEFT JOIN fact_orders o ON c.customer_id = o.customer_id AND o.total_amount IS NOT NULL
    GROUP BY c.customer_id, c.customer_name, c.channel, c.region, c.credit_limit, c.account_status, missing_email_flag;
    
SELECT * FROM vw_customer_account_health WHERE missing_email_flag = 1;
SELECT * FROM vw_customer_account_health WHERE account_status = 'Inactive' AND lifetime_revenue > 0 LIMIT 5;

CREATE OR REPLACE VIEW vw_low_stock_alerts AS
	SELECT
		p.product_name,
        p.category,
        p.reorder_level,
        s.store_name,
        s.region,
        s.brand,
        i.quantity_on_hand,
        (p.reorder_level - i.quantity_on_hand) AS shortfall,
        i.quantity_on_order,
        i.snapshot_date
    FROM fact_inventory i
    LEFT JOIN dim_products p ON i.product_id = p.product_id
    LEFT JOIN dim_stores s ON i.store_id = s.store_id
    WHERE i.quantity_on_hand < p.reorder_level
    ORDER BY shortfall DESC;
    
SELECT * FROM vw_low_stock_alerts LIMIT 3;

-- Data Quality Views 
-- Orphaned Products
CREATE VIEW vw_orphaned_products AS 
	SELECT
		o.order_id,
		o.order_date,
		o.product_id,
		o.store_id,
		o.customer_id
	FROM fact_orders o
	LEFT JOIN dim_products p ON o.product_id = p.product_id
	WHERE p.product_id IS NULL; 
    
SELECT COUNT(*) FROM vw_orphaned_products;

-- duplicate orders

CREATE VIEW vw_duplicate_orders AS
	SELECT
		order_date, store_id, product_id, customer_id, quantity, total_amount,
		COUNT(*) AS duplicate_count
	FROM fact_orders
	GROUP BY order_date, store_id, product_id, customer_id, quantity, total_amount
	HAVING COUNT(*) > 1;

SELECT COUNT(*) FROM vw_duplicate_orders;
SELECT SUM(duplicate_count - 1) FROM vw_duplicate_orders;

-- missing emails

CREATE VIEW vw_missing_emails AS
	SELECT
		*
    FROM dim_customers c 
    WHERE c.email IS NULL;
    
SELECT COUNT(*) FROM vw_missing_emails;

CREATE VIEW vw_null_totals AS
	SELECT 
		o.order_id, o.order_date, o.store_id, o.product_id, o.customer_id
    FROM fact_orders o
    WHERE o.total_amount IS NULL;

SELECT COUNT(*) FROM vw_null_totals;

CREATE VIEW vw_inactive_with_sales AS
	SELECT
		c.customer_id,
        c.customer_name,
        c.channel,
        c.region,
        c.credit_limit,
        c.account_status,
        MAX(o.order_date) AS last_order_date
    FROM dim_customers c
    LEFT JOIN fact_orders o ON c.customer_id = o.customer_id AND o.total_amount IS NOT NULL
    WHERE c.account_status = 'Inactive'
    GROUP BY c.customer_id, c.customer_name, c.channel, c.region, c.credit_limit, c.account_status
    HAVING COUNT(o.order_id) > 0;
    
SELECT COUNT(*) FROM vw_inactive_with_sales;
