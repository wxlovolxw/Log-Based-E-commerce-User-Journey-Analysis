-- Log-Based E-commerce User Journey Analysis
-- MySQL physical schema draft based on docs/table_specification.md.
-- This file contains CREATE TABLE statements only.

CREATE TABLE users (
    user_id VARCHAR(50) NOT NULL,
    signup_date DATE NULL,
    user_type VARCHAR(20) NOT NULL,
    age_group VARCHAR(20) NULL,
    gender VARCHAR(20) NULL,
    PRIMARY KEY (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE categories (
    category_id VARCHAR(50) NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    parent_category_id VARCHAR(50) NULL,
    PRIMARY KEY (category_id),
    CONSTRAINT fk_categories_parent_category
        FOREIGN KEY (parent_category_id)
        REFERENCES categories (category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE products (
    product_id VARCHAR(50) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    category_id VARCHAR(50) NOT NULL,
    brand VARCHAR(100) NULL,
    price DECIMAL(10,2) NOT NULL,
    created_at DATETIME NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (product_id),
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES categories (category_id),
    CONSTRAINT chk_products_price_non_negative
        CHECK (price >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE sessions (
    session_id VARCHAR(50) NOT NULL,
    user_id VARCHAR(50) NOT NULL,
    session_start_time DATETIME NOT NULL,
    session_end_time DATETIME NULL,
    traffic_source VARCHAR(50) NULL,
    medium VARCHAR(50) NULL,
    campaign VARCHAR(100) NULL,
    device_type VARCHAR(30) NULL,
    platform VARCHAR(30) NULL,
    landing_page VARCHAR(255) NULL,
    PRIMARY KEY (session_id),
    CONSTRAINT fk_sessions_user
        FOREIGN KEY (user_id)
        REFERENCES users (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE orders (
    order_id VARCHAR(50) NOT NULL,
    user_id VARCHAR(50) NOT NULL,
    session_id VARCHAR(50) NOT NULL,
    order_timestamp DATETIME NOT NULL,
    total_value DECIMAL(12,2) NOT NULL,
    payment_method VARCHAR(30) NULL,
    order_status VARCHAR(30) NOT NULL,
    PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_user
        FOREIGN KEY (user_id)
        REFERENCES users (user_id),
    CONSTRAINT fk_orders_session
        FOREIGN KEY (session_id)
        REFERENCES sessions (session_id),
    CONSTRAINT chk_orders_total_value_non_negative
        CHECK (total_value >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE order_items (
    order_item_id VARCHAR(50) NOT NULL,
    order_id VARCHAR(50) NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    quantity INT NOT NULL,
    item_price DECIMAL(10,2) NOT NULL,
    -- Although the logical specification allowed NULL, this physical draft uses
    -- NOT NULL DEFAULT 0 so item-level amount calculations can avoid NULL handling.
    discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    PRIMARY KEY (order_item_id),
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES orders (order_id),
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES products (product_id),
    CONSTRAINT chk_order_items_quantity_non_negative
        CHECK (quantity > 0),
    CONSTRAINT chk_order_items_item_price_non_negative
        CHECK (item_price >= 0),
    CONSTRAINT chk_order_items_discount_amount_non_negative
        CHECK (discount_amount >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE reviews (
    review_id VARCHAR(50) NOT NULL,
    user_id VARCHAR(50) NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    order_id VARCHAR(50) NOT NULL,
    rating TINYINT NOT NULL,
    review_length INT NULL,
    -- DEFAULT CURRENT_TIMESTAMP is applied because reviews.created_at is a
    -- required created-at style timestamp in the logical specification.
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (review_id),
    CONSTRAINT fk_reviews_user
        FOREIGN KEY (user_id)
        REFERENCES users (user_id),
    CONSTRAINT fk_reviews_product
        FOREIGN KEY (product_id)
        REFERENCES products (product_id),
    CONSTRAINT fk_reviews_order
        FOREIGN KEY (order_id)
        REFERENCES orders (order_id),
    CONSTRAINT chk_reviews_rating_range
        CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT chk_reviews_review_length_non_negative
        CHECK (review_length IS NULL OR review_length >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- event_logs is a single wide log table. Entity references such as product_id,
-- category_id, order_id, and review_id are nullable because not every event
-- refers to every entity.
-- event_logs.user_id and event_logs.session_id are both stored for user-level
-- analysis convenience. The consistency between event_logs.user_id and
-- sessions.user_id cannot be guaranteed by these foreign keys alone and will be
-- handled later in docs/data_quality_rules.md based quality check SQL.
CREATE TABLE event_logs (
    event_id VARCHAR(50) NOT NULL,
    event_name VARCHAR(50) NOT NULL,
    event_timestamp DATETIME NOT NULL,
    event_date DATE NOT NULL,
    user_id VARCHAR(50) NOT NULL,
    session_id VARCHAR(50) NOT NULL,
    product_id VARCHAR(50) NULL,
    category_id VARCHAR(50) NULL,
    order_id VARCHAR(50) NULL,
    review_id VARCHAR(50) NULL,
    search_term VARCHAR(255) NULL,
    list_id VARCHAR(100) NULL,
    page_number INT NULL,
    quantity INT NULL,
    price DECIMAL(10,2) NULL,
    items_count INT NULL,
    total_value DECIMAL(12,2) NULL,
    payment_method VARCHAR(30) NULL,
    rating TINYINT NULL,
    review_length INT NULL,
    PRIMARY KEY (event_id),
    CONSTRAINT fk_event_logs_user
        FOREIGN KEY (user_id)
        REFERENCES users (user_id),
    CONSTRAINT fk_event_logs_session
        FOREIGN KEY (session_id)
        REFERENCES sessions (session_id),
    CONSTRAINT fk_event_logs_product
        FOREIGN KEY (product_id)
        REFERENCES products (product_id),
    CONSTRAINT fk_event_logs_category
        FOREIGN KEY (category_id)
        REFERENCES categories (category_id),
    CONSTRAINT fk_event_logs_order
        FOREIGN KEY (order_id)
        REFERENCES orders (order_id),
    CONSTRAINT fk_event_logs_review
        FOREIGN KEY (review_id)
        REFERENCES reviews (review_id),
    CONSTRAINT chk_event_logs_page_number_non_negative
        CHECK (page_number IS NULL OR page_number >= 1),
    CONSTRAINT chk_event_logs_quantity_non_negative
        CHECK (quantity IS NULL OR quantity > 0),
    CONSTRAINT chk_event_logs_price_non_negative
        CHECK (price IS NULL OR price >= 0),
    CONSTRAINT chk_event_logs_items_count_non_negative
        CHECK (items_count IS NULL OR items_count > 0),
    CONSTRAINT chk_event_logs_total_value_non_negative
        CHECK (total_value IS NULL OR total_value >= 0),
    CONSTRAINT chk_event_logs_rating_range
        CHECK (rating IS NULL OR rating BETWEEN 1 AND 5),
    CONSTRAINT chk_event_logs_review_length_non_negative
        CHECK (review_length IS NULL OR review_length >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
