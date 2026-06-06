-- Funnel analysis queries for the Log-Based E-commerce User Journey Analysis project.
-- Purpose: answer the first core business question,
-- "Where do users drop off the most during the purchase journey?"
-- MySQL Workbench execution note: run each SELECT query independently in order.
-- This file intentionally contains SELECT queries only.

-- 1. Session-level event reach flags
-- This query answers which journey events each session experienced.
-- Each event column is a 0/1 flag aggregated at the session_id level.
WITH session_event_flags AS (
    SELECT
        session_id,
        MAX(CASE WHEN event_name = 'session_start' THEN 1 ELSE 0 END) AS reached_session_start,
        MAX(CASE WHEN event_name = 'search' THEN 1 ELSE 0 END) AS reached_search,
        MAX(CASE WHEN event_name = 'view_item_list' THEN 1 ELSE 0 END) AS reached_view_item_list,
        MAX(CASE WHEN event_name = 'view_item' THEN 1 ELSE 0 END) AS reached_view_item,
        MAX(CASE WHEN event_name = 'add_to_cart' THEN 1 ELSE 0 END) AS reached_add_to_cart,
        MAX(CASE WHEN event_name = 'begin_checkout' THEN 1 ELSE 0 END) AS reached_begin_checkout,
        MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS reached_purchase,
        MAX(CASE WHEN event_name = 'review_write' THEN 1 ELSE 0 END) AS reached_review_write
    FROM event_logs
    GROUP BY session_id
)
SELECT
    session_id,
    reached_session_start,
    reached_search,
    reached_view_item_list,
    reached_view_item,
    reached_add_to_cart,
    reached_begin_checkout,
    reached_purchase,
    reached_review_write
FROM session_event_flags
ORDER BY session_id;

-- 2. Funnel-stage reached session counts
-- This query answers how many distinct sessions reached each major funnel stage.
-- Major funnel stages are session_start, view_item, add_to_cart, begin_checkout, and purchase.
WITH funnel_events AS (
    SELECT DISTINCT
        session_id,
        event_name
    FROM event_logs
    WHERE event_name IN (
        'session_start',
        'view_item',
        'add_to_cart',
        'begin_checkout',
        'purchase'
    )
),
funnel_stage_counts AS (
    SELECT
        'session_start' AS funnel_stage,
        1 AS stage_order,
        COUNT(DISTINCT CASE WHEN event_name = 'session_start' THEN session_id END) AS reached_session_count
    FROM funnel_events
    UNION ALL
    SELECT
        'view_item' AS funnel_stage,
        2 AS stage_order,
        COUNT(DISTINCT CASE WHEN event_name = 'view_item' THEN session_id END) AS reached_session_count
    FROM funnel_events
    UNION ALL
    SELECT
        'add_to_cart' AS funnel_stage,
        3 AS stage_order,
        COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart' THEN session_id END) AS reached_session_count
    FROM funnel_events
    UNION ALL
    SELECT
        'begin_checkout' AS funnel_stage,
        4 AS stage_order,
        COUNT(DISTINCT CASE WHEN event_name = 'begin_checkout' THEN session_id END) AS reached_session_count
    FROM funnel_events
    UNION ALL
    SELECT
        'purchase' AS funnel_stage,
        5 AS stage_order,
        COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN session_id END) AS reached_session_count
    FROM funnel_events
)
SELECT
    funnel_stage,
    reached_session_count
FROM funnel_stage_counts
ORDER BY stage_order;

-- 3. Stage-by-stage conversion rates
-- This query answers both total reach rate from session_start and conversion rate from the previous stage.
-- Rates are returned as percentages, and NULLIF prevents division by zero.
WITH session_event_flags AS (
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
    FROM session_event_flags
),
conversion_rates AS (
    SELECT
        'session_start' AS funnel_stage,
        1 AS stage_order,
        session_start_sessions AS reached_session_count,
        ROUND(100.0 * session_start_sessions / NULLIF(session_start_sessions, 0), 2) AS session_start_reach_rate,
        NULL AS previous_stage_conversion_rate
    FROM funnel_counts
    UNION ALL
    SELECT
        'view_item' AS funnel_stage,
        2 AS stage_order,
        view_item_sessions AS reached_session_count,
        ROUND(100.0 * view_item_sessions / NULLIF(session_start_sessions, 0), 2) AS session_start_reach_rate,
        ROUND(100.0 * view_item_sessions / NULLIF(session_start_sessions, 0), 2) AS previous_stage_conversion_rate
    FROM funnel_counts
    UNION ALL
    SELECT
        'add_to_cart' AS funnel_stage,
        3 AS stage_order,
        add_to_cart_sessions AS reached_session_count,
        ROUND(100.0 * add_to_cart_sessions / NULLIF(session_start_sessions, 0), 2) AS session_start_reach_rate,
        ROUND(100.0 * add_to_cart_sessions / NULLIF(view_item_sessions, 0), 2) AS previous_stage_conversion_rate
    FROM funnel_counts
    UNION ALL
    SELECT
        'begin_checkout' AS funnel_stage,
        4 AS stage_order,
        begin_checkout_sessions AS reached_session_count,
        ROUND(100.0 * begin_checkout_sessions / NULLIF(session_start_sessions, 0), 2) AS session_start_reach_rate,
        ROUND(100.0 * begin_checkout_sessions / NULLIF(add_to_cart_sessions, 0), 2) AS previous_stage_conversion_rate
    FROM funnel_counts
    UNION ALL
    SELECT
        'purchase' AS funnel_stage,
        5 AS stage_order,
        purchase_sessions AS reached_session_count,
        ROUND(100.0 * purchase_sessions / NULLIF(session_start_sessions, 0), 2) AS session_start_reach_rate,
        ROUND(100.0 * purchase_sessions / NULLIF(begin_checkout_sessions, 0), 2) AS previous_stage_conversion_rate
    FROM funnel_counts
)
SELECT
    funnel_stage,
    reached_session_count,
    session_start_reach_rate,
    previous_stage_conversion_rate
FROM conversion_rates
ORDER BY stage_order;

-- 4. Session-level final reached stage classification
-- This query answers how far each session progressed in the journey.
-- review_write is post-purchase behavior, so it is interpreted separately from purchase funnel drop-off.
-- Purchase sessions are classified as completed later; review-only sessions without purchase funnel events
-- are classified as post_purchase_activity.
WITH session_event_flags AS (
    SELECT
        session_id,
        MAX(CASE WHEN event_name = 'session_start' THEN 1 ELSE 0 END) AS reached_session_start,
        MAX(CASE WHEN event_name = 'search' THEN 1 ELSE 0 END) AS reached_search,
        MAX(CASE WHEN event_name = 'view_item_list' THEN 1 ELSE 0 END) AS reached_view_item_list,
        MAX(CASE WHEN event_name = 'view_item' THEN 1 ELSE 0 END) AS reached_view_item,
        MAX(CASE WHEN event_name = 'add_to_cart' THEN 1 ELSE 0 END) AS reached_add_to_cart,
        MAX(CASE WHEN event_name = 'begin_checkout' THEN 1 ELSE 0 END) AS reached_begin_checkout,
        MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS reached_purchase,
        MAX(CASE WHEN event_name = 'review_write' THEN 1 ELSE 0 END) AS reached_review_write
    FROM event_logs
    GROUP BY session_id
),
session_final_stage AS (
    SELECT
        session_id,
        CASE
            WHEN reached_purchase = 1 THEN 'purchase'
            WHEN reached_review_write = 1
                 AND reached_view_item = 0
                 AND reached_add_to_cart = 0
                 AND reached_begin_checkout = 0 THEN 'post_purchase_activity'
            WHEN reached_begin_checkout = 1 THEN 'begin_checkout'
            WHEN reached_add_to_cart = 1 THEN 'add_to_cart'
            WHEN reached_view_item = 1 THEN 'view_item'
            WHEN reached_view_item_list = 1 THEN 'view_item_list'
            WHEN reached_search = 1 THEN 'search'
            WHEN reached_session_start = 1 THEN 'session_start'
        END AS final_reached_stage
    FROM session_event_flags
)
SELECT
    session_id,
    final_reached_stage
FROM session_final_stage
ORDER BY session_id;

-- 5. Drop-off session counts by final reached stage
-- This query answers where sessions stopped before purchase.
-- Sessions that reached purchase are classified as completed.
-- review_write is post-purchase behavior, so review-only sessions without purchase funnel events
-- are classified as post_purchase_activity instead of purchase funnel drop-off.
WITH session_event_flags AS (
    SELECT
        session_id,
        MAX(CASE WHEN event_name = 'session_start' THEN 1 ELSE 0 END) AS reached_session_start,
        MAX(CASE WHEN event_name = 'search' THEN 1 ELSE 0 END) AS reached_search,
        MAX(CASE WHEN event_name = 'view_item_list' THEN 1 ELSE 0 END) AS reached_view_item_list,
        MAX(CASE WHEN event_name = 'view_item' THEN 1 ELSE 0 END) AS reached_view_item,
        MAX(CASE WHEN event_name = 'add_to_cart' THEN 1 ELSE 0 END) AS reached_add_to_cart,
        MAX(CASE WHEN event_name = 'begin_checkout' THEN 1 ELSE 0 END) AS reached_begin_checkout,
        MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS reached_purchase,
        MAX(CASE WHEN event_name = 'review_write' THEN 1 ELSE 0 END) AS reached_review_write
    FROM event_logs
    GROUP BY session_id
),
session_final_stage AS (
    SELECT
        session_id,
        CASE
            WHEN reached_purchase = 1 THEN 'purchase'
            WHEN reached_review_write = 1
                 AND reached_view_item = 0
                 AND reached_add_to_cart = 0
                 AND reached_begin_checkout = 0 THEN 'post_purchase_activity'
            WHEN reached_begin_checkout = 1 THEN 'begin_checkout'
            WHEN reached_add_to_cart = 1 THEN 'add_to_cart'
            WHEN reached_view_item = 1 THEN 'view_item'
            WHEN reached_view_item_list = 1 THEN 'view_item_list'
            WHEN reached_search = 1 THEN 'search'
            WHEN reached_session_start = 1 THEN 'session_start'
        END AS final_reached_stage
    FROM session_event_flags
),
drop_off_summary AS (
    SELECT
        CASE
            WHEN final_reached_stage = 'purchase' THEN 'completed'
            ELSE final_reached_stage
        END AS drop_off_stage,
        CASE
            WHEN final_reached_stage = 'session_start' THEN 1
            WHEN final_reached_stage = 'search' THEN 2
            WHEN final_reached_stage = 'view_item_list' THEN 3
            WHEN final_reached_stage = 'view_item' THEN 4
            WHEN final_reached_stage = 'add_to_cart' THEN 5
            WHEN final_reached_stage = 'begin_checkout' THEN 6
            WHEN final_reached_stage = 'post_purchase_activity' THEN 7
            WHEN final_reached_stage = 'purchase' THEN 8
        END AS drop_off_stage_order,
        COUNT(DISTINCT session_id) AS session_count
    FROM session_final_stage
    GROUP BY
        CASE
            WHEN final_reached_stage = 'purchase' THEN 'completed'
            ELSE final_reached_stage
        END,
        CASE
            WHEN final_reached_stage = 'session_start' THEN 1
            WHEN final_reached_stage = 'search' THEN 2
            WHEN final_reached_stage = 'view_item_list' THEN 3
            WHEN final_reached_stage = 'view_item' THEN 4
            WHEN final_reached_stage = 'add_to_cart' THEN 5
            WHEN final_reached_stage = 'begin_checkout' THEN 6
            WHEN final_reached_stage = 'post_purchase_activity' THEN 7
            WHEN final_reached_stage = 'purchase' THEN 8
        END
)
SELECT
    drop_off_stage,
    session_count
FROM drop_off_summary
ORDER BY drop_off_stage_order;

-- 6. Purchase conversion rate by traffic source
-- This query answers which traffic sources drive the highest purchase conversion rate.
-- It uses sessions.traffic_source as the acquisition channel dimension.
WITH session_purchase_flags AS (
    SELECT
        s.session_id,
        COALESCE(s.traffic_source, 'unknown') AS traffic_source,
        MAX(CASE WHEN e.event_name = 'purchase' THEN 1 ELSE 0 END) AS reached_purchase
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
        SUM(reached_purchase) AS purchase_session_count,
        ROUND(100.0 * SUM(reached_purchase) / NULLIF(COUNT(DISTINCT session_id), 0), 2) AS purchase_conversion_rate
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
