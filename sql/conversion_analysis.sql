-- Conversion behavior analysis queries for the Log-Based E-commerce User Journey Analysis project.
-- Purpose: answer the second core business question,
-- "Which user behaviors are related to purchase conversion?"
-- MySQL Workbench execution note: run each SELECT query independently in order.
-- Current data is sample data from sql/seed_data.sql, not production service data.
-- Results should be used to validate query behavior and interpretation, not as service-level insights.
-- This file intentionally contains SELECT queries only.

-- 1. Session-level purchase flag and key behavior summary
-- This query answers what key behaviors each session performed and whether the session purchased.
WITH session_behavior_summary AS (
    SELECT
        s.session_id,
        COUNT(e.event_id) AS total_event_count,
        MAX(CASE WHEN e.event_name = 'search' THEN 1 ELSE 0 END) AS has_search,
        SUM(CASE WHEN e.event_name = 'view_item' THEN 1 ELSE 0 END) AS view_item_count,
        SUM(CASE WHEN e.event_name = 'add_to_cart' THEN 1 ELSE 0 END) AS add_to_cart_count,
        MAX(CASE WHEN e.event_name = 'begin_checkout' THEN 1 ELSE 0 END) AS has_begin_checkout,
        MAX(CASE WHEN e.event_name = 'purchase' THEN 1 ELSE 0 END) AS has_purchase
    FROM sessions s
    LEFT JOIN event_logs e
        ON s.session_id = e.session_id
    GROUP BY s.session_id
)
SELECT
    session_id,
    total_event_count,
    has_search,
    view_item_count,
    add_to_cart_count,
    has_begin_checkout,
    has_purchase
FROM session_behavior_summary
ORDER BY session_id;

-- 2. Average behavior volume by purchase status
-- This query answers how purchase sessions and non-purchase sessions differ in average behavior volume.
WITH session_behavior_summary AS (
    SELECT
        s.session_id,
        COUNT(e.event_id) AS total_event_count,
        MAX(CASE WHEN e.event_name = 'search' THEN 1 ELSE 0 END) AS has_search,
        SUM(CASE WHEN e.event_name = 'view_item' THEN 1 ELSE 0 END) AS view_item_count,
        SUM(CASE WHEN e.event_name = 'add_to_cart' THEN 1 ELSE 0 END) AS add_to_cart_count,
        MAX(CASE WHEN e.event_name = 'begin_checkout' THEN 1 ELSE 0 END) AS has_begin_checkout,
        MAX(CASE WHEN e.event_name = 'purchase' THEN 1 ELSE 0 END) AS has_purchase
    FROM sessions s
    LEFT JOIN event_logs e
        ON s.session_id = e.session_id
    GROUP BY s.session_id
),
purchase_status_summary AS (
    SELECT
        CASE
            WHEN has_purchase = 1 THEN 'purchase'
            ELSE 'non_purchase'
        END AS purchase_status,
        COUNT(DISTINCT session_id) AS session_count,
        ROUND(AVG(total_event_count), 2) AS avg_total_event_count,
        ROUND(AVG(view_item_count), 2) AS avg_view_item_count,
        ROUND(AVG(add_to_cart_count), 2) AS avg_add_to_cart_count,
        ROUND(100.0 * SUM(has_begin_checkout) / NULLIF(COUNT(DISTINCT session_id), 0), 2) AS begin_checkout_rate,
        ROUND(100.0 * SUM(has_search) / NULLIF(COUNT(DISTINCT session_id), 0), 2) AS search_rate
    FROM session_behavior_summary
    GROUP BY
        CASE
            WHEN has_purchase = 1 THEN 'purchase'
            ELSE 'non_purchase'
        END
)
SELECT
    purchase_status,
    session_count,
    avg_total_event_count,
    avg_view_item_count,
    avg_add_to_cart_count,
    begin_checkout_rate,
    search_rate
FROM purchase_status_summary
ORDER BY purchase_status;

-- 3. Purchase conversion rate by key event reach flag
-- This query answers whether sessions that reached each key event show different purchase conversion rates.
-- Target events are search, view_item, add_to_cart, and begin_checkout.
WITH session_behavior_summary AS (
    SELECT
        s.session_id,
        MAX(CASE WHEN e.event_name = 'search' THEN 1 ELSE 0 END) AS has_search,
        MAX(CASE WHEN e.event_name = 'view_item' THEN 1 ELSE 0 END) AS has_view_item,
        MAX(CASE WHEN e.event_name = 'add_to_cart' THEN 1 ELSE 0 END) AS has_add_to_cart,
        MAX(CASE WHEN e.event_name = 'begin_checkout' THEN 1 ELSE 0 END) AS has_begin_checkout,
        MAX(CASE WHEN e.event_name = 'purchase' THEN 1 ELSE 0 END) AS has_purchase
    FROM sessions s
    LEFT JOIN event_logs e
        ON s.session_id = e.session_id
    GROUP BY s.session_id
),
event_reach_flags AS (
    SELECT
        'search' AS event_name,
        has_search AS reached_event_flag,
        session_id,
        has_purchase
    FROM session_behavior_summary
    UNION ALL
    SELECT
        'view_item' AS event_name,
        has_view_item AS reached_event_flag,
        session_id,
        has_purchase
    FROM session_behavior_summary
    UNION ALL
    SELECT
        'add_to_cart' AS event_name,
        has_add_to_cart AS reached_event_flag,
        session_id,
        has_purchase
    FROM session_behavior_summary
    UNION ALL
    SELECT
        'begin_checkout' AS event_name,
        has_begin_checkout AS reached_event_flag,
        session_id,
        has_purchase
    FROM session_behavior_summary
),
event_conversion_summary AS (
    SELECT
        event_name,
        reached_event_flag,
        COUNT(DISTINCT session_id) AS session_count,
        SUM(has_purchase) AS purchase_session_count,
        ROUND(100.0 * SUM(has_purchase) / NULLIF(COUNT(DISTINCT session_id), 0), 2) AS purchase_conversion_rate
    FROM event_reach_flags
    GROUP BY
        event_name,
        reached_event_flag
)
SELECT
    event_name,
    reached_event_flag,
    session_count,
    purchase_session_count,
    purchase_conversion_rate
FROM event_conversion_summary
ORDER BY
    event_name,
    reached_event_flag DESC;

-- 4. Purchase conversion rate by product detail view count segment
-- This query answers how purchase conversion differs by the number of product detail views in a session.
WITH session_behavior_summary AS (
    SELECT
        s.session_id,
        SUM(CASE WHEN e.event_name = 'view_item' THEN 1 ELSE 0 END) AS view_item_count,
        MAX(CASE WHEN e.event_name = 'purchase' THEN 1 ELSE 0 END) AS has_purchase
    FROM sessions s
    LEFT JOIN event_logs e
        ON s.session_id = e.session_id
    GROUP BY s.session_id
),
view_item_segments AS (
    SELECT
        session_id,
        CASE
            WHEN view_item_count = 0 THEN '0'
            WHEN view_item_count = 1 THEN '1'
            ELSE '2+'
        END AS view_item_count_segment,
        CASE
            WHEN view_item_count = 0 THEN 1
            WHEN view_item_count = 1 THEN 2
            ELSE 3
        END AS segment_order,
        has_purchase
    FROM session_behavior_summary
),
segment_conversion_summary AS (
    SELECT
        view_item_count_segment,
        segment_order,
        COUNT(DISTINCT session_id) AS session_count,
        SUM(has_purchase) AS purchase_session_count,
        ROUND(100.0 * SUM(has_purchase) / NULLIF(COUNT(DISTINCT session_id), 0), 2) AS purchase_conversion_rate
    FROM view_item_segments
    GROUP BY
        view_item_count_segment,
        segment_order
)
SELECT
    view_item_count_segment,
    session_count,
    purchase_session_count,
    purchase_conversion_rate
FROM segment_conversion_summary
ORDER BY segment_order;

-- 5. Purchase conversion rate by add-to-cart count segment
-- This query answers how purchase conversion differs by the number of add-to-cart events in a session.
WITH session_behavior_summary AS (
    SELECT
        s.session_id,
        SUM(CASE WHEN e.event_name = 'add_to_cart' THEN 1 ELSE 0 END) AS add_to_cart_count,
        MAX(CASE WHEN e.event_name = 'purchase' THEN 1 ELSE 0 END) AS has_purchase
    FROM sessions s
    LEFT JOIN event_logs e
        ON s.session_id = e.session_id
    GROUP BY s.session_id
),
add_to_cart_segments AS (
    SELECT
        session_id,
        CASE
            WHEN add_to_cart_count = 0 THEN '0'
            WHEN add_to_cart_count = 1 THEN '1'
            ELSE '2+'
        END AS add_to_cart_count_segment,
        CASE
            WHEN add_to_cart_count = 0 THEN 1
            WHEN add_to_cart_count = 1 THEN 2
            ELSE 3
        END AS segment_order,
        has_purchase
    FROM session_behavior_summary
),
segment_conversion_summary AS (
    SELECT
        add_to_cart_count_segment,
        segment_order,
        COUNT(DISTINCT session_id) AS session_count,
        SUM(has_purchase) AS purchase_session_count,
        ROUND(100.0 * SUM(has_purchase) / NULLIF(COUNT(DISTINCT session_id), 0), 2) AS purchase_conversion_rate
    FROM add_to_cart_segments
    GROUP BY
        add_to_cart_count_segment,
        segment_order
)
SELECT
    add_to_cart_count_segment,
    session_count,
    purchase_session_count,
    purchase_conversion_rate
FROM segment_conversion_summary
ORDER BY segment_order;

-- 6. Purchase conversion rate by traffic source
-- This query answers how purchase conversion differs by sessions.traffic_source.
-- It is included here from the behavior-comparison perspective.
WITH session_purchase_flags AS (
    SELECT
        s.session_id,
        COALESCE(s.traffic_source, 'unknown') AS traffic_source,
        MAX(CASE WHEN e.event_name = 'purchase' THEN 1 ELSE 0 END) AS has_purchase
    FROM sessions s
    LEFT JOIN event_logs e
        ON s.session_id = e.session_id
    GROUP BY
        s.session_id,
        COALESCE(s.traffic_source, 'unknown')
),
traffic_source_conversion AS (
    SELECT
        traffic_source,
        COUNT(DISTINCT session_id) AS total_session_count,
        SUM(has_purchase) AS purchase_session_count,
        ROUND(100.0 * SUM(has_purchase) / NULLIF(COUNT(DISTINCT session_id), 0), 2) AS purchase_conversion_rate
    FROM session_purchase_flags
    GROUP BY traffic_source
)
SELECT
    traffic_source,
    total_session_count,
    purchase_session_count,
    purchase_conversion_rate
FROM traffic_source_conversion
ORDER BY
    purchase_conversion_rate DESC,
    total_session_count DESC,
    traffic_source;
