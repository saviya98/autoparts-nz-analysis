
DELIMITER //
CREATE PROCEDURE sp_refresh_sales_summary(IN p_start_date DATE, IN p_end_date DATE)
BEGIN
	DROP TABLE IF EXISTS sales_summary;
    
    CREATE TABLE sales_summary AS
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
		WHERE o.order_date BETWEEN p_start_date AND p_end_date AND o.total_amount IS NOT NULL
		GROUP BY s.region, s.channel, s.brand, d.year, d.month_name;
    
END //

DELIMITER ;

CALL sp_refresh_sales_summary('2025-01-01','2026-12-31');
SELECT COUNT(*) FROM sales_summary;
SELECT * FROM sales_summary ORDER BY total_revenue DESC LIMIT 5;