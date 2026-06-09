-- =========================================================
-- Manual SQL Practice
-- Project: Log-Based E-commerce User Journey Analysis
-- Purpose:
--   Rewrote core analysis queries manually to understand
--   funnel, conversion, and post-purchase behavior logic.
--
-- Dataset:
--   Synthetic data generated for analysis logic validation.
-- =========================================================

USE ecommerce_journey;


-- =========================================================
-- 1. Funnel stage reach and conversion rate
-- =========================================================
-- Purpose:
--   Calculate how many sessions reached each funnel stage,
--   the reach rate from session_start, and the conversion rate
--   from the previous funnel stage.
--
-- Funnel stages:
--   session_start -> view_item -> add_to_cart -> begin_checkout -> purchase
-- =========================================================

WITH sessions_flags AS (
    SELECT
        session_id,
        MAX(CASE WHEN event_name = 'session_start' THEN 1 ELSE 0 END) AS reached_session_start,
        MAX(CASE WHEN event_name = 'view_item' THEN 1 ELSE 0 END) AS reached_view_item,
        MAX(CASE WHEN event_name = 'add_to_cart' THEN 1 ELSE 0 END) AS reached_add_to_cart,
        MAX(CASE WHEN event_name = 'begin_checkout' THEN 1 ELSE 0 END) AS reached_begin_checkout,
        MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS reached_purchase
    FROM event_logs
    GROUP BY session_id
),
funnel_counts AS (
    SELECT 
        SUM(reached_session_start) AS session_start_sessions,
        SUM(reached_view_item) AS view_item_sessions,
        SUM(reached_add_to_cart) AS add_to_cart_sessions,
        SUM(reached_begin_checkout) AS begin_checkout_sessions,
        SUM(reached_purchase) AS purchase_sessions
    FROM sessions_flags
)
SELECT 
    'session_start' AS funnel_stage,
    session_start_sessions AS reached_session_count,
    ROUND(100.0 * session_start_sessions / NULLIF(session_start_sessions, 0), 2) AS session_start_reach_rate,
    NULL AS previous_stage_conversion_rate
FROM funnel_counts

UNION ALL

SELECT 
    'view_item' AS funnel_stage,
    view_item_sessions AS reached_session_count,
    ROUND(100.0 * view_item_sessions / NULLIF(session_start_sessions, 0), 2) AS session_start_reach_rate,
    ROUND(100.0 * view_item_sessions / NULLIF(session_start_sessions, 0), 2) AS previous_stage_conversion_rate
FROM funnel_counts

UNION ALL

SELECT
    'add_to_cart' AS funnel_stage,
    add_to_cart_sessions AS reached_session_count,
    ROUND(100.0 * add_to_cart_sessions / NULLIF(session_start_sessions, 0), 2) AS session_start_reach_rate,
    ROUND(100.0 * add_to_cart_sessions / NULLIF(view_item_sessions, 0), 2) AS previous_stage_conversion_rate
FROM funnel_counts

UNION ALL

SELECT
    'begin_checkout' AS funnel_stage,
    begin_checkout_sessions AS reached_session_count,
    ROUND(100.0 * begin_checkout_sessions / NULLIF(session_start_sessions, 0), 2) AS session_start_reach_rate,
    ROUND(100.0 * begin_checkout_sessions / NULLIF(add_to_cart_sessions, 0), 2) AS previous_stage_conversion_rate
FROM funnel_counts

UNION ALL

SELECT
    'purchase' AS funnel_stage,
    purchase_sessions AS reached_session_count,
    ROUND(100.0 * purchase_sessions / NULLIF(session_start_sessions, 0), 2) AS session_start_reach_rate,
    ROUND(100.0 * purchase_sessions / NULLIF(begin_checkout_sessions, 0), 2) AS previous_stage_conversion_rate
FROM funnel_counts;


-- =========================================================
-- 2. Purchase vs non-purchase session behavior comparison
-- =========================================================
-- Purpose:
--   Compare average session behaviors between purchase sessions
--   and non-purchase sessions.
--
-- Metrics:
--   - total event count
--   - view_item count
--   - add_to_cart count
--   - begin_checkout reach rate
--   - search reach rate
-- =========================================================

WITH session_summary AS (
    SELECT
        session_id,
        COUNT(*) AS total_event_count,
        MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS has_purchase,
        MAX(CASE WHEN event_name = 'search' THEN 1 ELSE 0 END) AS has_search,
        COUNT(CASE WHEN event_name = 'view_item' THEN 1 END) AS view_item_count,
        COUNT(CASE WHEN event_name = 'add_to_cart' THEN 1 END) AS add_to_cart_count,
        MAX(CASE WHEN event_name = 'begin_checkout' THEN 1 ELSE 0 END) AS has_begin_checkout
    FROM event_logs
    GROUP BY session_id
)
SELECT 
    CASE 
        WHEN has_purchase = 1 THEN 'purchase'
        ELSE 'non_purchase'
    END AS purchase_status,
    COUNT(*) AS session_count,
    ROUND(AVG(total_event_count), 2) AS avg_total_event_count,
    ROUND(AVG(view_item_count), 2) AS avg_view_item_count,
    ROUND(AVG(add_to_cart_count), 2) AS avg_add_to_cart_count,
    ROUND(100.0 * AVG(has_begin_checkout), 2) AS begin_checkout_rate,
    ROUND(100.0 * AVG(has_search), 2) AS search_rate
FROM session_summary
GROUP BY purchase_status;


-- =========================================================
-- 3. Conversion rate by event reach
-- =========================================================
-- Purpose:
--   Compare purchase conversion rates between sessions that
--   reached a specific event and sessions that did not.
--
-- Events:
--   search, view_item, add_to_cart, begin_checkout
-- =========================================================

WITH session_flags AS (
    SELECT
        session_id,
        MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS has_purchase,
        MAX(CASE WHEN event_name = 'search' THEN 1 ELSE 0 END) AS reached_search,
        MAX(CASE WHEN event_name = 'view_item' THEN 1 ELSE 0 END) AS reached_view_item,
        MAX(CASE WHEN event_name = 'add_to_cart' THEN 1 ELSE 0 END) AS reached_add_to_cart,
        MAX(CASE WHEN event_name = 'begin_checkout' THEN 1 ELSE 0 END) AS reached_begin_checkout
    FROM event_logs
    GROUP BY session_id
)
SELECT 
    'search' AS event_name,
    reached_search AS reached_flag,
    COUNT(*) AS session_count,
    SUM(has_purchase) AS purchase_session_count,
    ROUND(100.0 * SUM(has_purchase) / NULLIF(COUNT(*), 0), 2) AS purchase_conversion_rate
FROM session_flags
GROUP BY reached_search

UNION ALL

SELECT 
    'view_item' AS event_name,
    reached_view_item AS reached_flag,
    COUNT(*) AS session_count,
    SUM(has_purchase) AS purchase_session_count,
    ROUND(100.0 * SUM(has_purchase) / NULLIF(COUNT(*), 0), 2) AS purchase_conversion_rate
FROM session_flags
GROUP BY reached_view_item

UNION ALL

SELECT 
    'add_to_cart' AS event_name,
    reached_add_to_cart AS reached_flag,
    COUNT(*) AS session_count,
    SUM(has_purchase) AS purchase_session_count,
    ROUND(100.0 * SUM(has_purchase) / NULLIF(COUNT(*), 0), 2) AS purchase_conversion_rate
FROM session_flags
GROUP BY reached_add_to_cart

UNION ALL

SELECT 
    'begin_checkout' AS event_name,
    reached_begin_checkout AS reached_flag,
    COUNT(*) AS session_count,
    SUM(has_purchase) AS purchase_session_count,
    ROUND(100.0 * SUM(has_purchase) / NULLIF(COUNT(*), 0), 2) AS purchase_conversion_rate
FROM session_flags
GROUP BY reached_begin_checkout;


-- =========================================================
-- 4. Conversion rate by add-to-cart count segment
-- =========================================================
-- Purpose:
--   Segment sessions by add_to_cart count and compare purchase
--   conversion rates across segments.
--
-- Segments:
--   0, 1, 2+
-- =========================================================

WITH session_cart_summary AS (
    SELECT
        session_id,
        COUNT(CASE WHEN event_name = 'add_to_cart' THEN 1 END) AS add_to_cart_count,
        MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS has_purchase
    FROM event_logs
    GROUP BY session_id
)
SELECT 
    CASE
        WHEN add_to_cart_count = 0 THEN '0'
        WHEN add_to_cart_count = 1 THEN '1'
        ELSE '2+'
    END AS add_to_cart_segment,
    COUNT(*) AS session_count,
    SUM(has_purchase) AS purchase_session_count,
    ROUND(100.0 * SUM(has_purchase) / NULLIF(COUNT(*), 0), 2) AS purchase_conversion_rate
FROM session_cart_summary
GROUP BY add_to_cart_segment
ORDER BY
    CASE add_to_cart_segment
        WHEN '0' THEN 1
        WHEN '1' THEN 2
        ELSE 3
    END;


-- =========================================================
-- 5. Review rate after purchase
-- =========================================================
-- Purpose:
--   Calculate how many purchased orders have reviews.
--
-- Logic:
--   orders = all purchased orders
--   reviews = reviewed orders
-- =========================================================

SELECT
    COUNT(DISTINCT o.order_id) AS total_order_count,
    COUNT(DISTINCT r.order_id) AS reviewed_order_count,
    ROUND(
        100.0 * COUNT(DISTINCT r.order_id)
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS review_rate
FROM orders o
LEFT JOIN reviews r
    ON o.order_id = r.order_id;


-- =========================================================
-- 6. Review session type and delay after purchase
-- =========================================================
-- Purpose:
--   Classify review_write events based on whether the review was
--   written in the same session as the purchase or in a later session.
--
-- Logic:
--   same_purchase_session:
--      orders.session_id = event_logs.session_id
--
--   separate_post_purchase_session:
--      orders.session_id <> event_logs.session_id
--
-- Metrics:
--   - review count
--   - review share
--   - average minutes after purchase
--   - minimum / maximum minutes after purchase
-- =========================================================

WITH review_session_summary AS (
    SELECT
        r.review_id,
        r.order_id,
        o.session_id AS order_session_id,
        e.session_id AS review_event_session_id,
        CASE
            WHEN o.session_id = e.session_id THEN 'same_purchase_session'
            ELSE 'separate_post_purchase_session'
        END AS review_session_type,
        o.order_timestamp,
        e.event_timestamp AS review_event_timestamp,
        TIMESTAMPDIFF(MINUTE, o.order_timestamp, e.event_timestamp) AS minutes_after_purchase
    FROM reviews r
    JOIN orders o
        ON r.order_id = o.order_id
    JOIN event_logs e
        ON r.review_id = e.review_id
    WHERE e.event_name = 'review_write'
)
SELECT
    review_session_type,
    COUNT(*) AS review_count,
    ROUND(
        100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM review_session_summary), 0),
        2
    ) AS review_share,
    ROUND(AVG(minutes_after_purchase), 2) AS avg_minutes_after_purchase,
    MIN(minutes_after_purchase) AS min_minutes_after_purchase,
    MAX(minutes_after_purchase) AS max_minutes_after_purchase
FROM review_session_summary
GROUP BY review_session_type;

