-- Data quality validation queries for the Log-Based E-commerce User Journey Analysis project.
-- MySQL 기준 정합성 검증용 SQL입니다.
-- 각 SELECT 쿼리는 문제가 있는 행을 반환하며, 정상 데이터라면 결과가 0건이어야 합니다.

-- 1. event_logs.user_id와 sessions.user_id가 동일한 session_id 기준으로 일치해야 한다.
SELECT
    e.event_id,
    e.session_id,
    e.user_id AS event_user_id,
    s.user_id AS session_user_id
FROM event_logs e
JOIN sessions s
    ON e.session_id = s.session_id
WHERE e.user_id <> s.user_id;

-- 2. orders.user_id와 sessions.user_id가 동일한 session_id 기준으로 일치해야 한다.
SELECT
    o.order_id,
    o.session_id,
    o.user_id AS order_user_id,
    s.user_id AS session_user_id
FROM orders o
JOIN sessions s
    ON o.session_id = s.session_id
WHERE o.user_id <> s.user_id;

-- 3. purchase 이벤트의 order_id가 orders.order_id에 존재해야 한다.
SELECT
    e.event_id,
    e.event_name,
    e.order_id
FROM event_logs e
LEFT JOIN orders o
    ON e.order_id = o.order_id
WHERE e.event_name = 'purchase'
  AND (e.order_id IS NULL OR o.order_id IS NULL);

-- 4. purchase 이벤트의 user_id/session_id가 연결된 orders와 일치해야 한다.
SELECT
    e.event_id,
    e.order_id,
    e.user_id AS event_user_id,
    o.user_id AS order_user_id,
    e.session_id AS event_session_id,
    o.session_id AS order_session_id
FROM event_logs e
JOIN orders o
    ON e.order_id = o.order_id
WHERE e.event_name = 'purchase'
  AND (
      e.user_id <> o.user_id
      OR e.session_id <> o.session_id
  );

-- 5. products.category_id가 categories.category_id에 존재해야 한다.
SELECT
    p.product_id,
    p.category_id
FROM products p
LEFT JOIN categories c
    ON p.category_id = c.category_id
WHERE c.category_id IS NULL;

-- 6. 상품 관련 event_logs.product_id가 products.product_id에 존재해야 한다.
SELECT
    e.event_id,
    e.event_name,
    e.product_id
FROM event_logs e
LEFT JOIN products p
    ON e.product_id = p.product_id
WHERE e.event_name IN ('view_item', 'add_to_cart', 'review_write')
  AND (e.product_id IS NULL OR p.product_id IS NULL);

-- 7. order_items.order_id가 orders.order_id에 존재해야 한다.
SELECT
    oi.order_item_id,
    oi.order_id
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 8. order_items.product_id가 products.product_id에 존재해야 한다.
SELECT
    oi.order_item_id,
    oi.product_id
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- 9. orders.total_value와 order_items 기준 합계가 일관되어야 한다.
SELECT
    o.order_id,
    o.total_value AS order_total_value,
    item_totals.calculated_total_value
FROM orders o
LEFT JOIN (
    SELECT
        order_id,
        SUM((quantity * item_price) - discount_amount) AS calculated_total_value
    FROM order_items
    GROUP BY order_id
) item_totals
    ON o.order_id = item_totals.order_id
WHERE item_totals.order_id IS NULL
   OR o.total_value <> item_totals.calculated_total_value;

-- 10. reviews.user_id, product_id, order_id가 각각 users, products, orders에 존재해야 한다.
SELECT
    r.review_id,
    r.user_id,
    r.product_id,
    r.order_id
FROM reviews r
LEFT JOIN users u
    ON r.user_id = u.user_id
LEFT JOIN products p
    ON r.product_id = p.product_id
LEFT JOIN orders o
    ON r.order_id = o.order_id
WHERE u.user_id IS NULL
   OR p.product_id IS NULL
   OR o.order_id IS NULL;

-- 11. reviews.user_id가 연결된 orders.user_id와 일치해야 한다.
SELECT
    r.review_id,
    r.order_id,
    r.user_id AS review_user_id,
    o.user_id AS order_user_id
FROM reviews r
JOIN orders o
    ON r.order_id = o.order_id
WHERE r.user_id <> o.user_id;

-- 12. reviews의 order_id, product_id 조합이 order_items에 존재해야 한다.
SELECT
    r.review_id,
    r.order_id,
    r.product_id
FROM reviews r
LEFT JOIN order_items oi
    ON r.order_id = oi.order_id
   AND r.product_id = oi.product_id
WHERE oi.order_item_id IS NULL;

-- 13. review_write 이벤트의 review_id가 reviews.review_id에 존재해야 한다.
SELECT
    e.event_id,
    e.event_name,
    e.review_id
FROM event_logs e
LEFT JOIN reviews r
    ON e.review_id = r.review_id
WHERE e.event_name = 'review_write'
  AND (e.review_id IS NULL OR r.review_id IS NULL);

-- 14. review_write 이벤트의 user_id/product_id/order_id가 연결된 reviews와 일치해야 한다.
SELECT
    e.event_id,
    e.review_id,
    e.user_id AS event_user_id,
    r.user_id AS review_user_id,
    e.product_id AS event_product_id,
    r.product_id AS review_product_id,
    e.order_id AS event_order_id,
    r.order_id AS review_order_id
FROM event_logs e
JOIN reviews r
    ON e.review_id = r.review_id
WHERE e.event_name = 'review_write'
  AND (
      e.user_id <> r.user_id
      OR e.product_id <> r.product_id
      OR e.order_id <> r.order_id
  );

-- 15. event_logs.event_date는 DATE(event_logs.event_timestamp)와 일치해야 한다.
SELECT
    e.event_id,
    e.event_timestamp,
    e.event_date,
    DATE(e.event_timestamp) AS timestamp_date
FROM event_logs e
WHERE e.event_date <> DATE(e.event_timestamp);

-- 16. sessions.session_end_time이 session_start_time보다 빠르면 안 된다.
SELECT
    s.session_id,
    s.session_start_time,
    s.session_end_time
FROM sessions s
WHERE s.session_end_time IS NOT NULL
  AND s.session_end_time < s.session_start_time;

-- 17. orders.order_timestamp가 해당 session_start_time보다 빠르면 안 된다.
SELECT
    o.order_id,
    o.session_id,
    s.session_start_time,
    o.order_timestamp
FROM orders o
JOIN sessions s
    ON o.session_id = s.session_id
WHERE o.order_timestamp < s.session_start_time;

-- 18. reviews.created_at이 해당 order_timestamp보다 빠르면 안 된다.
SELECT
    r.review_id,
    r.order_id,
    o.order_timestamp,
    r.created_at
FROM reviews r
JOIN orders o
    ON r.order_id = o.order_id
WHERE r.created_at < o.order_timestamp;
