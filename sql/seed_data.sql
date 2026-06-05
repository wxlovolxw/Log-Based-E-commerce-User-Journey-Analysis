-- Sample seed data for the Log-Based E-commerce User Journey Analysis project.
-- This dataset is designed to test funnel analysis, drop-off analysis, and
-- future data quality checks against the schema defined in sql/schema.sql.
-- This file contains INSERT statements only.

-- users
INSERT INTO users (user_id, signup_date, user_type, age_group, gender) VALUES
    ('u001', '2026-01-05', 'member', '30s', 'female'),
    ('u002', '2026-01-12', 'member', '20s', 'male'),
    ('u003', NULL, 'guest', NULL, NULL),
    ('u004', '2026-02-03', 'member', '40s', 'female'),
    ('u005', NULL, 'guest', NULL, NULL);

-- categories
INSERT INTO categories (category_id, category_name, parent_category_id) VALUES
    ('c001', 'Electronics', NULL),
    ('c002', 'Home', NULL),
    ('c003', 'Fashion', NULL),
    ('c004', 'Sports', NULL);

-- products
INSERT INTO products (product_id, product_name, category_id, brand, price, created_at, is_active) VALUES
    ('p001', 'Wireless Headphones', 'c001', 'SoundMax', 799.00, '2026-01-01 09:00:00', TRUE),
    ('p002', 'USB C Charger', 'c001', 'VoltPro', 349.00, '2026-01-01 09:10:00', TRUE),
    ('p003', 'Air Purifier', 'c002', 'CleanHome', 1299.00, '2026-01-02 10:00:00', TRUE),
    ('p004', 'Coffee Maker', 'c002', 'BrewLab', 899.00, '2026-01-02 10:20:00', TRUE),
    ('p005', 'Running Shoes', 'c003', 'RunPeak', 1099.00, '2026-01-03 11:00:00', TRUE),
    ('p006', 'Denim Jacket', 'c003', 'UrbanFit', 1499.00, '2026-01-03 11:30:00', TRUE),
    ('p007', 'Yoga Mat', 'c004', 'FlexWay', 299.00, '2026-01-04 12:00:00', TRUE),
    ('p008', 'Dumbbell Set', 'c004', 'IronCore', 699.00, '2026-01-04 12:30:00', TRUE);

-- sessions
INSERT INTO sessions (
    session_id,
    user_id,
    session_start_time,
    session_end_time,
    traffic_source,
    medium,
    campaign,
    device_type,
    platform,
    landing_page
) VALUES
    ('s001', 'u001', '2026-06-01 09:00:00', '2026-06-01 09:16:00', 'google', 'organic', NULL, 'mobile', 'web', '/home'),
    ('s002', 'u002', '2026-06-01 10:00:00', '2026-06-01 10:18:00', 'google', 'cpc', 'summer_sale', 'desktop', 'web', '/search'),
    ('s003', 'u003', '2026-06-01 11:00:00', '2026-06-01 11:03:00', 'direct', 'none', NULL, 'mobile', 'web', '/home'),
    ('s004', 'u004', '2026-06-01 12:00:00', '2026-06-01 12:08:00', 'email', 'newsletter', 'june_news', 'desktop', 'web', '/category/electronics'),
    ('s005', 'u005', '2026-06-01 13:00:00', '2026-06-01 13:07:00', 'instagram', 'social', 'sports_push', 'mobile', 'app', '/product/p007'),
    ('s006', 'u001', '2026-06-03 15:00:00', '2026-06-03 15:04:00', 'direct', 'none', NULL, 'mobile', 'app', '/orders'),
    ('s007', 'u003', '2026-06-04 16:00:00', '2026-06-04 16:10:00', 'google', 'organic', NULL, 'desktop', 'web', '/category/fashion'),
    ('s008', 'u004', '2026-06-05 17:00:00', '2026-06-05 17:22:00', 'affiliate', 'referral', 'home_deal', 'mobile', 'web', '/search');

-- orders
INSERT INTO orders (order_id, user_id, session_id, order_timestamp, total_value, payment_method, order_status) VALUES
    ('o001', 'u001', 's001', '2026-06-01 09:15:00', 1148.00, 'card', 'paid'),
    ('o002', 'u002', 's002', '2026-06-01 10:15:00', 1299.00, 'paypal', 'paid'),
    ('o003', 'u004', 's008', '2026-06-05 17:18:00', 1798.00, 'card', 'paid');

-- order_items
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, item_price, discount_amount) VALUES
    ('oi001', 'o001', 'p001', 1, 799.00, 0.00),
    ('oi002', 'o001', 'p002', 1, 349.00, 0.00),
    ('oi003', 'o002', 'p003', 1, 1299.00, 0.00),
    ('oi004', 'o003', 'p004', 1, 899.00, 0.00),
    ('oi005', 'o003', 'p005', 1, 1099.00, 200.00),
    ('oi006', 'o003', 'p007', 1, 299.00, 299.00);

-- reviews
INSERT INTO reviews (review_id, user_id, product_id, order_id, rating, review_length, created_at) VALUES
    ('r001', 'u002', 'p003', 'o002', 5, 128, '2026-06-01 10:18:00'),
    ('r002', 'u001', 'p002', 'o001', 4, 76, '2026-06-03 15:03:00'),
    ('r003', 'u004', 'p004', 'o003', 5, 92, '2026-06-05 17:21:00');

-- event_logs
INSERT INTO event_logs (
    event_id,
    event_name,
    event_timestamp,
    event_date,
    user_id,
    session_id,
    product_id,
    category_id,
    order_id,
    review_id,
    search_term,
    list_id,
    page_number,
    quantity,
    price,
    items_count,
    total_value,
    payment_method,
    rating,
    review_length
) VALUES
    ('e001', 'session_start', '2026-06-01 09:00:00', '2026-06-01', 'u001', 's001', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e002', 'view_item_list', '2026-06-01 09:02:00', '2026-06-01', 'u001', 's001', NULL, 'c001', NULL, NULL, NULL, 'electronics_home', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e003', 'view_item', '2026-06-01 09:04:00', '2026-06-01', 'u001', 's001', 'p001', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e004', 'add_to_cart', '2026-06-01 09:06:00', '2026-06-01', 'u001', 's001', 'p001', NULL, NULL, NULL, NULL, NULL, NULL, 1, 799.00, NULL, NULL, NULL, NULL, NULL),
    ('e005', 'view_item', '2026-06-01 09:08:00', '2026-06-01', 'u001', 's001', 'p002', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e006', 'add_to_cart', '2026-06-01 09:10:00', '2026-06-01', 'u001', 's001', 'p002', NULL, NULL, NULL, NULL, NULL, NULL, 1, 349.00, NULL, NULL, NULL, NULL, NULL),
    ('e007', 'begin_checkout', '2026-06-01 09:13:00', '2026-06-01', 'u001', 's001', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 1148.00, NULL, NULL, NULL),
    ('e008', 'purchase', '2026-06-01 09:15:00', '2026-06-01', 'u001', 's001', NULL, NULL, 'o001', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1148.00, 'card', NULL, NULL),

    ('e009', 'session_start', '2026-06-01 10:00:00', '2026-06-01', 'u002', 's002', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e010', 'search', '2026-06-01 10:02:00', '2026-06-01', 'u002', 's002', NULL, NULL, NULL, NULL, 'air purifier', NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e011', 'view_item_list', '2026-06-01 10:04:00', '2026-06-01', 'u002', 's002', NULL, 'c002', NULL, NULL, NULL, 'search_air_purifier', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e012', 'view_item', '2026-06-01 10:06:00', '2026-06-01', 'u002', 's002', 'p003', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e013', 'add_to_cart', '2026-06-01 10:08:00', '2026-06-01', 'u002', 's002', 'p003', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1299.00, NULL, NULL, NULL, NULL, NULL),
    ('e014', 'begin_checkout', '2026-06-01 10:12:00', '2026-06-01', 'u002', 's002', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1299.00, NULL, NULL, NULL),
    ('e015', 'purchase', '2026-06-01 10:15:00', '2026-06-01', 'u002', 's002', NULL, NULL, 'o002', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1299.00, 'paypal', NULL, NULL),
    ('e016', 'review_write', '2026-06-01 10:18:00', '2026-06-01', 'u002', 's002', 'p003', NULL, 'o002', 'r001', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 5, 128),

    ('e017', 'session_start', '2026-06-01 11:00:00', '2026-06-01', 'u003', 's003', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e018', 'search', '2026-06-01 11:02:00', '2026-06-01', 'u003', 's003', NULL, NULL, NULL, NULL, 'running shoes', NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),

    ('e019', 'session_start', '2026-06-01 12:00:00', '2026-06-01', 'u004', 's004', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e020', 'view_item_list', '2026-06-01 12:02:00', '2026-06-01', 'u004', 's004', NULL, 'c001', NULL, NULL, NULL, 'electronics_category', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e021', 'view_item', '2026-06-01 12:05:00', '2026-06-01', 'u004', 's004', 'p002', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),

    ('e022', 'session_start', '2026-06-01 13:00:00', '2026-06-01', 'u005', 's005', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e023', 'view_item', '2026-06-01 13:02:00', '2026-06-01', 'u005', 's005', 'p007', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e024', 'add_to_cart', '2026-06-01 13:05:00', '2026-06-01', 'u005', 's005', 'p007', NULL, NULL, NULL, NULL, NULL, NULL, 1, 299.00, NULL, NULL, NULL, NULL, NULL),

    ('e025', 'session_start', '2026-06-03 15:00:00', '2026-06-03', 'u001', 's006', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e026', 'review_write', '2026-06-03 15:03:00', '2026-06-03', 'u001', 's006', 'p002', NULL, 'o001', 'r002', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, 76),

    ('e027', 'session_start', '2026-06-04 16:00:00', '2026-06-04', 'u003', 's007', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e028', 'view_item_list', '2026-06-04 16:02:00', '2026-06-04', 'u003', 's007', NULL, 'c003', NULL, NULL, NULL, 'fashion_category', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e029', 'view_item', '2026-06-04 16:04:00', '2026-06-04', 'u003', 's007', 'p005', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e030', 'add_to_cart', '2026-06-04 16:06:00', '2026-06-04', 'u003', 's007', 'p005', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1099.00, NULL, NULL, NULL, NULL, NULL),
    ('e031', 'begin_checkout', '2026-06-04 16:08:00', '2026-06-04', 'u003', 's007', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1099.00, NULL, NULL, NULL),

    ('e032', 'session_start', '2026-06-05 17:00:00', '2026-06-05', 'u004', 's008', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e033', 'search', '2026-06-05 17:02:00', '2026-06-05', 'u004', 's008', NULL, NULL, NULL, NULL, 'coffee maker', NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e034', 'view_item_list', '2026-06-05 17:04:00', '2026-06-05', 'u004', 's008', NULL, 'c002', NULL, NULL, NULL, 'search_coffee_maker', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e035', 'view_item', '2026-06-05 17:06:00', '2026-06-05', 'u004', 's008', 'p004', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e036', 'add_to_cart', '2026-06-05 17:08:00', '2026-06-05', 'u004', 's008', 'p004', NULL, NULL, NULL, NULL, NULL, NULL, 1, 899.00, NULL, NULL, NULL, NULL, NULL),
    ('e040', 'view_item', '2026-06-05 17:10:00', '2026-06-05', 'u004', 's008', 'p005', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e041', 'add_to_cart', '2026-06-05 17:11:00', '2026-06-05', 'u004', 's008', 'p005', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1099.00, NULL, NULL, NULL, NULL, NULL),
    ('e042', 'view_item', '2026-06-05 17:12:00', '2026-06-05', 'u004', 's008', 'p007', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
    ('e043', 'add_to_cart', '2026-06-05 17:13:00', '2026-06-05', 'u004', 's008', 'p007', NULL, NULL, NULL, NULL, NULL, NULL, 1, 299.00, NULL, NULL, NULL, NULL, NULL),
    ('e037', 'begin_checkout', '2026-06-05 17:16:00', '2026-06-05', 'u004', 's008', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, 1798.00, NULL, NULL, NULL),
    ('e038', 'purchase', '2026-06-05 17:19:00', '2026-06-05', 'u004', 's008', NULL, NULL, 'o003', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1798.00, 'card', NULL, NULL),
    ('e039', 'review_write', '2026-06-05 17:21:00', '2026-06-05', 'u004', 's008', 'p004', NULL, 'o003', 'r003', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 5, 92);
