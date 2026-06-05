-- Basic validation queries for checking that schema.sql and seed_data.sql
-- executed successfully.
-- This file is only for simple execution checks. Full data quality checks will
-- be handled later in quality_checks.sql.

-- Table row counts
SELECT 'users' AS table_name, COUNT(*) AS row_count FROM users
UNION ALL
SELECT 'categories' AS table_name, COUNT(*) AS row_count FROM categories
UNION ALL
SELECT 'products' AS table_name, COUNT(*) AS row_count FROM products
UNION ALL
SELECT 'sessions' AS table_name, COUNT(*) AS row_count FROM sessions
UNION ALL
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM orders
UNION ALL
SELECT 'order_items' AS table_name, COUNT(*) AS row_count FROM order_items
UNION ALL
SELECT 'reviews' AS table_name, COUNT(*) AS row_count FROM reviews
UNION ALL
SELECT 'event_logs' AS table_name, COUNT(*) AS row_count FROM event_logs;

-- event_logs should contain 43 rows in the current seed dataset.
SELECT
    COUNT(*) AS event_logs_row_count,
    CASE
        WHEN COUNT(*) = 43 THEN 'PASS'
        ELSE 'CHECK'
    END AS expected_43_rows
FROM event_logs;

-- Purchase events should join to their orders and sessions.
SELECT
    e.event_id,
    e.event_name,
    e.user_id AS event_user_id,
    e.session_id AS event_session_id,
    e.order_id,
    o.total_value AS order_total_value,
    o.payment_method,
    s.user_id AS session_user_id
FROM event_logs e
JOIN orders o
    ON e.order_id = o.order_id
JOIN sessions s
    ON e.session_id = s.session_id
WHERE e.event_name = 'purchase'
ORDER BY e.event_timestamp;

-- Review write events should join to their review records.
SELECT
    e.event_id,
    e.event_name,
    e.user_id AS event_user_id,
    e.product_id AS event_product_id,
    e.order_id AS event_order_id,
    e.review_id,
    r.rating AS review_rating,
    r.review_length
FROM event_logs e
JOIN reviews r
    ON e.review_id = r.review_id
WHERE e.event_name = 'review_write'
ORDER BY e.event_timestamp;
