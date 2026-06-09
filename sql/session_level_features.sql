-- Session-level feature dataset for purchase conversion modeling.
-- Purpose: create a session_id-level feature dataset that can be exported as
-- outputs/session_level_features.csv and used later in Python modeling.
--
-- Modeling notes:
-- - event_count means the number of session behavior events used as predictive
--   signals, excluding purchase and review_write.
-- - purchase is the target event and is used only to create is_purchase.
--   It is intentionally excluded from feature-side count columns to reduce
--   target leakage.
-- - review_write is a post-purchase behavior and is intentionally excluded
--   from purchase prediction features.
-- - begin_checkout is a near-purchase behavior. It is included here because it
--   is analytically useful, but Python modeling should compare variants with
--   and without begin_checkout_count / has_begin_checkout.
-- - session_duration_minutes uses TIMESTAMPDIFF(MINUTE, first_predictive_event, last_predictive_event)
--   based on behavior events excluding purchase and review_write. This keeps the
--   duration feature aligned with the prediction-time behavior feature standard.
--   Sessions that start and end within the same minute can be calculated as 0.
--
-- Export options:
-- 1. MySQL Workbench: run the main SELECT query and use Result Grid export to
--    save the result as outputs/session_level_features.csv.
-- 2. MySQL server-side export example, if secure_file_priv allows the target
--    path. Replace the path with an allowed absolute path on your MySQL server.
--
-- SELECT ... INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/session_level_features.csv'
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"'
-- LINES TERMINATED BY '\n';

-- Main dataset query
USE ecommerce_journey;

WITH session_level_features AS (
    SELECT
        s.session_id,
        s.user_id,
        COUNT(CASE
            WHEN e.event_name NOT IN ('purchase', 'review_write') THEN e.event_id
        END) AS event_count,
        SUM(CASE WHEN e.event_name = 'search' THEN 1 ELSE 0 END) AS search_count,
        SUM(CASE WHEN e.event_name = 'view_item_list' THEN 1 ELSE 0 END) AS view_item_list_count,
        SUM(CASE WHEN e.event_name = 'view_item' THEN 1 ELSE 0 END) AS view_item_count,
        SUM(CASE WHEN e.event_name = 'add_to_cart' THEN 1 ELSE 0 END) AS add_to_cart_count,
        SUM(CASE WHEN e.event_name = 'begin_checkout' THEN 1 ELSE 0 END) AS begin_checkout_count,
        COUNT(DISTINCT CASE
            WHEN e.event_name NOT IN ('purchase', 'review_write') THEN e.product_id
        END) AS unique_product_count,
        COUNT(DISTINCT CASE
            WHEN e.event_name NOT IN ('purchase', 'review_write') THEN e.category_id
        END) AS unique_category_count,
        TIMESTAMPDIFF(
            MINUTE,
            MIN(CASE
                WHEN e.event_name NOT IN ('purchase', 'review_write') THEN e.event_timestamp
            END),
            MAX(CASE
                WHEN e.event_name NOT IN ('purchase', 'review_write') THEN e.event_timestamp
            END)
        ) AS session_duration_minutes,
        MAX(CASE WHEN e.event_name = 'search' THEN 1 ELSE 0 END) AS has_search,
        MAX(CASE WHEN e.event_name = 'view_item_list' THEN 1 ELSE 0 END) AS has_view_item_list,
        MAX(CASE WHEN e.event_name = 'view_item' THEN 1 ELSE 0 END) AS has_view_item,
        MAX(CASE WHEN e.event_name = 'add_to_cart' THEN 1 ELSE 0 END) AS has_add_to_cart,
        MAX(CASE WHEN e.event_name = 'begin_checkout' THEN 1 ELSE 0 END) AS has_begin_checkout,
        MAX(CASE WHEN e.event_name = 'purchase' THEN 1 ELSE 0 END) AS is_purchase
    FROM sessions s
    LEFT JOIN event_logs e
        ON s.session_id = e.session_id
    GROUP BY
        s.session_id,
        s.user_id
)
SELECT
    session_id,
    user_id,
    event_count,
    search_count,
    view_item_list_count,
    view_item_count,
    add_to_cart_count,
    begin_checkout_count,
    unique_product_count,
    unique_category_count,
    COALESCE(session_duration_minutes, 0) AS session_duration_minutes,
    has_search,
    has_view_item_list,
    has_view_item,
    has_add_to_cart,
    has_begin_checkout,
    is_purchase
FROM session_level_features
ORDER BY session_id;

-- Row count check
WITH session_level_features AS (
    SELECT
        s.session_id
    FROM sessions s
    LEFT JOIN event_logs e
        ON s.session_id = e.session_id
    GROUP BY s.session_id
)
SELECT
    session_counts.sessions_row_count,
    feature_counts.session_level_features_row_count,
    session_counts.sessions_row_count - feature_counts.session_level_features_row_count AS row_count_diff
FROM (
    SELECT COUNT(*) AS sessions_row_count
    FROM sessions
) AS session_counts
CROSS JOIN (
    SELECT COUNT(*) AS session_level_features_row_count
    FROM session_level_features
) AS feature_counts;

-- Target distribution check before modeling
WITH session_level_features AS (
    SELECT
        s.session_id,
        MAX(CASE WHEN e.event_name = 'purchase' THEN 1 ELSE 0 END) AS is_purchase
    FROM sessions s
    LEFT JOIN event_logs e
        ON s.session_id = e.session_id
    GROUP BY s.session_id
)
SELECT
    is_purchase,
    COUNT(*) AS session_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS session_share_pct
FROM session_level_features
GROUP BY is_purchase
ORDER BY is_purchase DESC;

-- Session duration summary check
WITH session_level_features AS (
    SELECT
        s.session_id,
        TIMESTAMPDIFF(
            MINUTE,
            MIN(CASE
                WHEN e.event_name NOT IN ('purchase', 'review_write') THEN e.event_timestamp
            END),
            MAX(CASE
                WHEN e.event_name NOT IN ('purchase', 'review_write') THEN e.event_timestamp
            END)
        ) AS session_duration_minutes
    FROM sessions s
    LEFT JOIN event_logs e
        ON s.session_id = e.session_id
    GROUP BY s.session_id
)
SELECT
    MIN(COALESCE(session_duration_minutes, 0)) AS min_session_duration_minutes,
    MAX(COALESCE(session_duration_minutes, 0)) AS max_session_duration_minutes,
    ROUND(AVG(COALESCE(session_duration_minutes, 0)), 2) AS avg_session_duration_minutes
FROM session_level_features;

-- Duration leakage check: compare previous full-event duration with predictive-event duration
WITH duration_comparison AS (
    SELECT
        s.session_id,
        TIMESTAMPDIFF(
            MINUTE,
            MIN(e.event_timestamp),
            MAX(e.event_timestamp)
        ) AS full_event_duration_minutes,
        TIMESTAMPDIFF(
            MINUTE,
            MIN(CASE
                WHEN e.event_name NOT IN ('purchase', 'review_write') THEN e.event_timestamp
            END),
            MAX(CASE
                WHEN e.event_name NOT IN ('purchase', 'review_write') THEN e.event_timestamp
            END)
        ) AS predictive_event_duration_minutes
    FROM sessions s
    LEFT JOIN event_logs e
        ON s.session_id = e.session_id
    GROUP BY s.session_id
)
SELECT
    COUNT(*) AS session_count,
    SUM(
        CASE
            WHEN COALESCE(full_event_duration_minutes, 0)
                <> COALESCE(predictive_event_duration_minutes, 0)
                THEN 1
            ELSE 0
        END
    ) AS changed_session_count,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN COALESCE(full_event_duration_minutes, 0)
                    <> COALESCE(predictive_event_duration_minutes, 0)
                    THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS changed_session_share_pct,
    MIN(COALESCE(full_event_duration_minutes, 0) - COALESCE(predictive_event_duration_minutes, 0)) AS min_duration_diff_minutes,
    MAX(COALESCE(full_event_duration_minutes, 0) - COALESCE(predictive_event_duration_minutes, 0)) AS max_duration_diff_minutes,
    ROUND(AVG(COALESCE(full_event_duration_minutes, 0) - COALESCE(predictive_event_duration_minutes, 0)), 2) AS avg_duration_diff_minutes
FROM duration_comparison;
