-- Post-purchase behavior analysis queries for the Log-Based E-commerce User Journey Analysis project.
-- Purpose: answer the third core business question,
-- "What do users do after purchase?"
-- MySQL Workbench execution note: run each SELECT query independently in order.
-- Current data is sample data from sql/seed_data.sql, not production service data.
-- Results should be used to validate query behavior and interpretation, not as service-level insights.
-- This file intentionally contains SELECT queries only.

-- 1. Review completion flag by order
-- This query answers whether each order led to at least one review.
WITH order_review_summary AS (
    SELECT
        o.order_id,
        o.user_id,
        o.order_timestamp,
        CASE
            WHEN COUNT(r.review_id) > 0 THEN 1
            ELSE 0
        END AS reviewed_flag,
        COUNT(r.review_id) AS review_count
    FROM orders o
    LEFT JOIN reviews r
        ON o.order_id = r.order_id
    GROUP BY
        o.order_id,
        o.user_id,
        o.order_timestamp
)
SELECT
    order_id,
    user_id,
    order_timestamp,
    reviewed_flag,
    review_count
FROM order_review_summary
ORDER BY order_timestamp, order_id;

-- 2. Post-purchase review rate
-- This query answers what share of orders received at least one review.
-- reviewed_order_count uses DISTINCT order_id because one order can have multiple reviews.
WITH order_review_flags AS (
    SELECT
        o.order_id,
        CASE
            WHEN COUNT(r.review_id) > 0 THEN 1
            ELSE 0
        END AS reviewed_flag
    FROM orders o
    LEFT JOIN reviews r
        ON o.order_id = r.order_id
    GROUP BY o.order_id
),
review_rate_summary AS (
    SELECT
        COUNT(DISTINCT order_id) AS total_order_count,
        COUNT(DISTINCT CASE WHEN reviewed_flag = 1 THEN order_id END) AS reviewed_order_count,
        ROUND(
            100.0 * COUNT(DISTINCT CASE WHEN reviewed_flag = 1 THEN order_id END)
            / NULLIF(COUNT(DISTINCT order_id), 0),
            2
        ) AS review_rate
    FROM order_review_flags
)
SELECT
    total_order_count,
    reviewed_order_count,
    review_rate
FROM review_rate_summary;

-- 3. Time from purchase to review
-- This query answers how many minutes passed between order completion and review creation.
WITH review_time_diff AS (
    SELECT
        r.review_id,
        r.order_id,
        r.user_id,
        r.product_id,
        TIMESTAMPDIFF(MINUTE, o.order_timestamp, r.created_at) AS minutes_to_review
    FROM reviews r
    JOIN orders o
        ON r.order_id = o.order_id
)
SELECT
    review_id,
    order_id,
    user_id,
    product_id,
    minutes_to_review
FROM review_time_diff
ORDER BY minutes_to_review, review_id;

-- 4. Same-session vs separate-session review classification
-- This query answers whether review_write happened in the purchase session or a later separate session.
WITH review_session_summary AS (
    SELECT
        r.review_id,
        r.order_id,
        r.user_id,
        r.product_id,
        o.session_id AS purchase_session_id,
        e.session_id AS review_session_id,
        CASE
            WHEN e.session_id = o.session_id THEN 'same_purchase_session'
            ELSE 'separate_post_purchase_session'
        END AS review_session_type
    FROM reviews r
    JOIN orders o
        ON r.order_id = o.order_id
    JOIN event_logs e
        ON r.review_id = e.review_id
       AND e.event_name = 'review_write'
)
SELECT
    review_id,
    order_id,
    user_id,
    product_id,
    purchase_session_id,
    review_session_id,
    review_session_type
FROM review_session_summary
ORDER BY review_id;

-- 5. Review count and average rating by product
-- This query answers which products have reviews and what their average rating is.
-- Products without reviews are included through LEFT JOIN.
WITH product_review_summary AS (
    SELECT
        p.product_id,
        p.product_name,
        COUNT(r.review_id) AS review_count,
        ROUND(AVG(r.rating), 2) AS avg_rating
    FROM products p
    LEFT JOIN reviews r
        ON p.product_id = r.product_id
    GROUP BY
        p.product_id,
        p.product_name
)
SELECT
    product_id,
    product_name,
    review_count,
    avg_rating
FROM product_review_summary
ORDER BY
    review_count DESC,
    product_id;

-- 6. User-level purchase and review summary
-- This query answers how many orders and reviews each user has.
-- All users are included through users LEFT JOIN orders and reviews.
-- review_rate is reviewed_order_count divided by order_count.
WITH user_order_review_summary AS (
    SELECT
        u.user_id,
        COUNT(DISTINCT o.order_id) AS order_count,
        COUNT(DISTINCT CASE WHEN r.review_id IS NOT NULL THEN o.order_id END) AS reviewed_order_count,
        COUNT(DISTINCT r.review_id) AS review_count
    FROM users u
    LEFT JOIN orders o
        ON u.user_id = o.user_id
    LEFT JOIN reviews r
        ON o.order_id = r.order_id
    GROUP BY u.user_id
),
user_review_rate AS (
    SELECT
        user_id,
        order_count,
        reviewed_order_count,
        review_count,
        ROUND(100.0 * reviewed_order_count / NULLIF(order_count, 0), 2) AS review_rate
    FROM user_order_review_summary
)
SELECT
    user_id,
    order_count,
    reviewed_order_count,
    review_count,
    review_rate
FROM user_review_rate
ORDER BY user_id;

-- 7. Review session type share
-- This query answers what share of reviews were written in the purchase session
-- versus a separate post-purchase session.
-- It reuses the same review_session_type classification logic as query 4.
WITH review_session_summary AS (
    SELECT
        r.review_id,
        CASE
            WHEN e.session_id = o.session_id THEN 'same_purchase_session'
            ELSE 'separate_post_purchase_session'
        END AS review_session_type
    FROM reviews r
    JOIN orders o
        ON r.order_id = o.order_id
    JOIN event_logs e
        ON r.review_id = e.review_id
       AND e.event_name = 'review_write'
),
review_session_type_summary AS (
    SELECT
        review_session_type,
        COUNT(DISTINCT review_id) AS review_count
    FROM review_session_summary
    GROUP BY review_session_type
)
SELECT
    review_session_type,
    review_count,
    ROUND(
        100.0 * review_count / NULLIF(SUM(review_count) OVER (), 0),
        2
    ) AS review_type_rate
FROM review_session_type_summary
ORDER BY review_session_type;
