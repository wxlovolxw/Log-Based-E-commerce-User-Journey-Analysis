from __future__ import annotations

import random
from collections import defaultdict
from datetime import datetime, timedelta
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path


SEED = 20260607
USER_COUNT = 300
CATEGORY_COUNT = 4
PRODUCT_COUNT = 30
SESSION_COUNT = 1000
TARGET_ORDER_MIN = 250
TARGET_ORDER_MAX = 350
REVIEW_RATE_MIN = 0.30
REVIEW_RATE_MAX = 0.40
OUTPUT_PATH = Path("sql") / "seed_synthetic_data.sql"


random.seed(SEED)


def money(value: float | Decimal) -> Decimal:
    return Decimal(str(value)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def sql_value(value):
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "TRUE" if value else "FALSE"
    if isinstance(value, Decimal):
        return f"{value:.2f}"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, datetime):
        return f"'{value.strftime('%Y-%m-%d %H:%M:%S')}'"
    if hasattr(value, "strftime"):
        return f"'{value.strftime('%Y-%m-%d')}'"
    escaped = str(value).replace("\\", "\\\\").replace("'", "''")
    return f"'{escaped}'"


def row_sql(row: tuple) -> str:
    return "(" + ", ".join(sql_value(value) for value in row) + ")"


def write_insert(lines: list[str], table_name: str, columns: list[str], rows: list[tuple], batch_size: int = 500) -> None:
    if not rows:
        return

    for start in range(0, len(rows), batch_size):
        batch = rows[start:start + batch_size]
        lines.append(f"INSERT INTO {table_name} ({', '.join(columns)}) VALUES")
        lines.append(",\n".join(row_sql(row) for row in batch) + ";")
        lines.append("")


def id_value(prefix: str, number: int, width: int = 3) -> str:
    return f"{prefix}{number:0{width}d}"


def weighted_choice(options: list[tuple[str | None, float]]) -> str | None:
    values, weights = zip(*options)
    return random.choices(values, weights=weights, k=1)[0]


def product_price(product_id: str, products_by_id: dict[str, tuple]) -> Decimal:
    return products_by_id[product_id][4]


def event_row(
    event_id: str,
    event_name: str,
    event_timestamp: datetime,
    user_id: str,
    session_id: str,
    product_id=None,
    category_id=None,
    order_id=None,
    review_id=None,
    search_term=None,
    list_id=None,
    page_number=None,
    quantity=None,
    price=None,
    items_count=None,
    total_value=None,
    payment_method=None,
    rating=None,
    review_length=None,
) -> tuple:
    return (
        event_id,
        event_name,
        event_timestamp,
        event_timestamp.date(),
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
        review_length,
    )


def generate_users() -> list[tuple]:
    rows = []
    base_date = datetime(2025, 1, 1)
    for idx in range(1, USER_COUNT + 1):
        user_id = id_value("u", idx)
        user_type = weighted_choice([("member", 0.72), ("guest", 0.28)])
        signup_date = None
        if user_type == "member":
            signup_date = (base_date + timedelta(days=random.randint(0, 500))).date()
        age_group = weighted_choice([("20s", 0.24), ("30s", 0.28), ("40s", 0.22), ("50s", 0.12), (None, 0.14)])
        gender = weighted_choice([("male", 0.45), ("female", 0.45), (None, 0.10)])
        rows.append((user_id, signup_date, user_type, age_group, gender))
    return rows


def generate_categories() -> list[tuple]:
    return [
        ("c001", "Electronics", None),
        ("c002", "Home", None),
        ("c003", "Fashion", None),
        ("c004", "Sports", None),
    ]


def generate_products(categories: list[tuple]) -> list[tuple]:
    product_words = [
        "Headphones", "Charger", "Speaker", "Monitor", "Keyboard", "Mouse", "Camera", "Tablet",
        "Air Purifier", "Coffee Maker", "Lamp", "Chair", "Desk", "Vacuum", "Cookware", "Blender",
        "Running Shoes", "Jacket", "Backpack", "T-Shirt", "Sneakers", "Cap", "Watch",
        "Yoga Mat", "Dumbbell Set", "Water Bottle", "Bike Helmet", "Tennis Racket", "Fitness Band", "Soccer Ball",
    ]
    brands = ["Nova", "Peak", "Urban", "Core", "Fresh", "Bright", "Flex", "Prime"]
    rows = []
    for idx in range(1, PRODUCT_COUNT + 1):
        product_id = id_value("p", idx)
        category_id = categories[(idx - 1) % CATEGORY_COUNT][0]
        product_name = f"{random.choice(brands)} {product_words[idx - 1]}"
        brand = random.choice(brands) + "Co"
        price = money(random.randint(100, 2000))
        created_at = datetime(2026, 1, 1, 9, 0, 0) + timedelta(days=idx)
        rows.append((product_id, product_name, category_id, brand, price, created_at, True))
    return rows


def generate_sessions(users: list[tuple]) -> list[dict]:
    traffic_config = {
        "google": ("organic", None),
        "direct": ("none", None),
        "email": ("newsletter", "june_news"),
        "instagram": ("social", "social_push"),
        "affiliate": ("referral", "partner_deal"),
    }
    landing_pages = ["/home", "/search", "/category/electronics", "/category/home", "/category/fashion", "/category/sports"]
    sessions = []
    base_time = datetime(2026, 6, 1, 0, 0, 0)
    user_ids = [row[0] for row in users]

    for idx in range(1, SESSION_COUNT + 1):
        session_id = id_value("s", idx)
        user_id = random.choice(user_ids)
        session_start_time = base_time + timedelta(minutes=random.randint(0, 60 * 24 * 30))
        session_end_time = session_start_time + timedelta(minutes=random.randint(3, 45))
        traffic_source = weighted_choice([
            ("google", 0.36),
            ("direct", 0.22),
            ("email", 0.14),
            ("instagram", 0.18),
            ("affiliate", 0.10),
        ])
        medium, campaign = traffic_config[traffic_source]
        device_type = weighted_choice([("mobile", 0.64), ("desktop", 0.36)])
        platform = weighted_choice([("web", 0.72), ("app", 0.28)])
        landing_page = random.choice(landing_pages)
        sessions.append({
            "session_id": session_id,
            "user_id": user_id,
            "session_start_time": session_start_time,
            "session_end_time": session_end_time,
            "traffic_source": traffic_source,
            "medium": medium,
            "campaign": campaign,
            "device_type": device_type,
            "platform": platform,
            "landing_page": landing_page,
        })
    return sorted(sessions, key=lambda row: row["session_start_time"])


def session_rows(sessions: list[dict]) -> list[tuple]:
    return [
        (
            row["session_id"],
            row["user_id"],
            row["session_start_time"],
            row["session_end_time"],
            row["traffic_source"],
            row["medium"],
            row["campaign"],
            row["device_type"],
            row["platform"],
            row["landing_page"],
        )
        for row in sorted(sessions, key=lambda item: item["session_id"])
    ]


def build_purchase_probability(session: dict) -> float:
    source_bonus = {
        "affiliate": 0.08,
        "google": 0.04,
        "email": 0.03,
        "instagram": -0.02,
        "direct": -0.04,
    }[session["traffic_source"]]
    device_bonus = 0.02 if session["device_type"] == "desktop" else 0.00
    return max(0.12, min(0.46, 0.29 + source_bonus + device_bonus))


def generate_journey_data(sessions: list[dict], products: list[tuple]) -> tuple[list[tuple], list[tuple], list[tuple]]:
    products_by_id = {row[0]: row for row in products}
    product_ids = list(products_by_id)
    product_category = {row[0]: row[2] for row in products}
    target_order_count = random.randint(TARGET_ORDER_MIN, TARGET_ORDER_MAX)
    weighted_sessions = sorted(sessions, key=lambda item: build_purchase_probability(item), reverse=True)
    purchase_session_ids = {row["session_id"] for row in weighted_sessions[:target_order_count]}

    event_rows = []
    order_rows = []
    order_item_rows = []
    order_by_id = {}
    order_items_by_order = defaultdict(list)
    event_counter = 1
    order_counter = 1
    order_item_counter = 1

    for session in sessions:
        session_id = session["session_id"]
        user_id = session["user_id"]
        current_time = session["session_start_time"]

        def add_event(event_name: str, minutes: int = 1, **kwargs) -> None:
            nonlocal event_counter, current_time
            current_time = current_time + timedelta(minutes=minutes)
            event_rows.append(event_row(id_value("e", event_counter, 6), event_name, current_time, user_id, session_id, **kwargs))
            event_counter += 1
            session["session_end_time"] = max(session["session_end_time"], current_time + timedelta(minutes=2))

        event_rows.append(event_row(id_value("e", event_counter, 6), "session_start", current_time, user_id, session_id))
        event_counter += 1

        is_purchase_session = session_id in purchase_session_ids
        has_search = random.random() < (0.58 if is_purchase_session else 0.38)
        has_view_list = random.random() < (0.76 if is_purchase_session else 0.50)

        if has_search:
            search_term = random.choice(["headphones", "coffee maker", "running shoes", "air purifier", "yoga mat", "desk lamp"])
            add_event("search", minutes=random.randint(1, 3), search_term=search_term, page_number=1)

        selected_category = random.choice(["c001", "c002", "c003", "c004"])
        if has_view_list:
            add_event(
                "view_item_list",
                minutes=random.randint(1, 3),
                category_id=selected_category,
                list_id=f"list_{selected_category}",
                page_number=random.randint(1, 3),
            )

        if is_purchase_session:
            view_count = random.randint(1, 5)
            viewed_products = random.sample(product_ids, view_count)
            for product_id in viewed_products:
                add_event("view_item", minutes=random.randint(1, 4), product_id=product_id)

            item_count = random.randint(1, min(4, len(viewed_products)))
            cart_products = random.sample(viewed_products, item_count)
            order_id = id_value("o", order_counter)
            payment_method = random.choice(["card", "paypal", "bank_transfer"])
            total_value = money(0)
            order_items_for_current_order = []

            for product_id in cart_products:
                quantity = random.randint(1, 3)
                item_price = product_price(product_id, products_by_id)
                discount_amount = money(item_price * Decimal(str(random.choice([0, 0, 0.05, 0.10]))) * quantity)
                total_value += money((item_price * quantity) - discount_amount)
                add_event(
                    "add_to_cart",
                    minutes=random.randint(1, 3),
                    product_id=product_id,
                    quantity=quantity,
                    price=item_price,
                )
                order_item_id = id_value("oi", order_item_counter, 5)
                order_item = (order_item_id, order_id, product_id, quantity, item_price, discount_amount)
                order_item_rows.append(order_item)
                order_items_for_current_order.append(order_item)
                order_item_counter += 1

            add_event("begin_checkout", minutes=random.randint(2, 5), items_count=item_count, total_value=total_value)
            purchase_time = current_time + timedelta(minutes=random.randint(2, 5))
            event_rows.append(event_row(
                id_value("e", event_counter, 6),
                "purchase",
                purchase_time,
                user_id,
                session_id,
                order_id=order_id,
                total_value=total_value,
                payment_method=payment_method,
            ))
            event_counter += 1
            session["session_end_time"] = max(session["session_end_time"], purchase_time + timedelta(minutes=2))
            order_row = (order_id, user_id, session_id, purchase_time, total_value, payment_method, "paid")
            order_rows.append(order_row)
            order_by_id[order_id] = {
                "order_id": order_id,
                "user_id": user_id,
                "session_id": session_id,
                "order_timestamp": purchase_time,
                "items": order_items_for_current_order,
            }
            order_items_by_order[order_id] = order_items_for_current_order
            order_counter += 1
            continue

        max_stage = weighted_choice([
            ("session_start", 0.16),
            ("view_item", 0.42),
            ("add_to_cart", 0.28),
            ("begin_checkout", 0.14),
        ])

        if max_stage in ("view_item", "add_to_cart", "begin_checkout"):
            view_count = random.randint(1, 3)
            viewed_products = random.sample(product_ids, view_count)
            for product_id in viewed_products:
                add_event("view_item", minutes=random.randint(1, 5), product_id=product_id)

            if max_stage in ("add_to_cart", "begin_checkout"):
                cart_products = random.sample(viewed_products, random.randint(1, len(viewed_products)))
                cart_total = money(0)
                for product_id in cart_products:
                    quantity = random.randint(1, 2)
                    item_price = product_price(product_id, products_by_id)
                    cart_total += money(item_price * quantity)
                    add_event(
                        "add_to_cart",
                        minutes=random.randint(1, 4),
                        product_id=product_id,
                        quantity=quantity,
                        price=item_price,
                    )
                if max_stage == "begin_checkout":
                    add_event("begin_checkout", minutes=random.randint(2, 5), items_count=len(cart_products), total_value=cart_total)

    return order_rows, order_item_rows, event_rows, order_by_id, order_items_by_order


def generate_reviews(
    sessions: list[dict],
    orders: list[tuple],
    order_by_id: dict,
    order_items_by_order: dict,
    event_rows: list[tuple],
) -> list[tuple]:
    sessions_by_user = defaultdict(list)
    for session in sessions:
        sessions_by_user[session["user_id"]].append(session)
    for user_sessions in sessions_by_user.values():
        user_sessions.sort(key=lambda item: item["session_start_time"])

    review_rate = random.uniform(REVIEW_RATE_MIN, REVIEW_RATE_MAX)
    review_count = round(len(orders) * review_rate)
    review_orders = random.sample([row[0] for row in orders], review_count)
    reviews = []
    event_counter = len(event_rows) + 1

    for idx, order_id in enumerate(review_orders, start=1):
        order = order_by_id[order_id]
        order_item = random.choice(order_items_by_order[order_id])
        product_id = order_item[2]
        user_id = order["user_id"]
        review_id = id_value("r", idx)
        rating = random.choices([1, 2, 3, 4, 5], weights=[0.04, 0.08, 0.18, 0.32, 0.38], k=1)[0]
        review_length = random.randint(20, 300)
        separate_candidates = [
            session for session in sessions_by_user[user_id]
            if session["session_id"] != order["session_id"]
            and session["session_start_time"] > order["order_timestamp"] + timedelta(hours=1)
        ]
        use_separate_session = bool(separate_candidates) and random.random() < 0.45

        if use_separate_session:
            review_session = random.choice(separate_candidates)
            review_timestamp = review_session["session_start_time"] + timedelta(minutes=random.randint(1, 20))
        else:
            review_session = next(session for session in sessions if session["session_id"] == order["session_id"])
            review_timestamp = order["order_timestamp"] + timedelta(minutes=random.randint(2, 20))

        review_session["session_end_time"] = max(review_session["session_end_time"], review_timestamp + timedelta(minutes=2))
        reviews.append((review_id, user_id, product_id, order_id, rating, review_length, review_timestamp))
        event_rows.append(event_row(
            id_value("e", event_counter, 6),
            "review_write",
            review_timestamp,
            user_id,
            review_session["session_id"],
            product_id=product_id,
            order_id=order_id,
            review_id=review_id,
            rating=rating,
            review_length=review_length,
        ))
        event_counter += 1

    return reviews


def validate_data(
    sessions: list[dict],
    orders: list[tuple],
    order_items: list[tuple],
    reviews: list[tuple],
    event_logs: list[tuple],
) -> None:
    session_user = {session["session_id"]: session["user_id"] for session in sessions}
    order_user = {order[0]: order[1] for order in orders}
    order_session = {order[0]: order[2] for order in orders}
    order_total = {order[0]: order[4] for order in orders}
    order_item_products = {(item[1], item[2]) for item in order_items}
    calculated_order_totals = defaultdict(lambda: money(0))

    for item in order_items:
        order_id = item[1]
        quantity = item[3]
        item_price = item[4]
        discount_amount = item[5]
        assert quantity > 0
        assert item_price >= 0
        assert discount_amount >= 0
        calculated_order_totals[order_id] += money((item_price * quantity) - discount_amount)

    for order in orders:
        order_id, user_id, session_id, _, total_value, _, order_status = order
        assert session_user[session_id] == user_id
        assert total_value == calculated_order_totals[order_id]
        assert order_status == "paid"

    for review in reviews:
        review_id, user_id, product_id, order_id, rating, review_length, _ = review
        assert review_id
        assert order_user[order_id] == user_id
        assert (order_id, product_id) in order_item_products
        assert 1 <= rating <= 5
        assert 20 <= review_length <= 300

    for event in event_logs:
        event_timestamp = event[2]
        event_date = event[3]
        user_id = event[4]
        session_id = event[5]
        order_id = event[8]
        quantity = event[13]
        price = event[14]
        items_count = event[15]
        total_value = event[16]
        rating = event[18]
        review_length = event[19]

        assert event_date == event_timestamp.date()
        assert session_user[session_id] == user_id
        if order_id is not None:
            assert order_user[order_id] == user_id
            assert order_session[order_id] in session_user
        if quantity is not None:
            assert quantity > 0
        if price is not None:
            assert price >= 0
        if items_count is not None:
            assert items_count > 0
        if total_value is not None:
            assert total_value >= 0
        if rating is not None:
            assert 1 <= rating <= 5
        if review_length is not None:
            assert review_length >= 0


def main() -> None:
    users = generate_users()
    categories = generate_categories()
    products = generate_products(categories)
    sessions = generate_sessions(users)
    orders, order_items, event_logs, order_by_id, order_items_by_order = generate_journey_data(sessions, products)
    reviews = generate_reviews(sessions, orders, order_by_id, order_items_by_order, event_logs)
    validate_data(sessions, orders, order_items, reviews, event_logs)

    root_dir = Path(__file__).resolve().parents[1]
    output_file = root_dir / OUTPUT_PATH
    output_file.parent.mkdir(parents=True, exist_ok=True)

    lines = [
        "-- Synthetic seed data for the Log-Based E-commerce User Journey Analysis project.",
        "-- Purpose: provide larger sample data for expanded SQL analysis.",
        "-- Generated by scripts/generate_synthetic_data.py.",
        f"-- Random seed: {SEED}.",
        "-- Scale: users 300, categories 4, products 30, sessions 1000, orders 250-350, reviews about 30-40% of orders.",
        "-- This file contains INSERT statements only and does not create tables.",
        "",
    ]

    write_insert(lines, "users", ["user_id", "signup_date", "user_type", "age_group", "gender"], users)
    write_insert(lines, "categories", ["category_id", "category_name", "parent_category_id"], categories)
    write_insert(lines, "products", ["product_id", "product_name", "category_id", "brand", "price", "created_at", "is_active"], products)
    write_insert(lines, "sessions", [
        "session_id",
        "user_id",
        "session_start_time",
        "session_end_time",
        "traffic_source",
        "medium",
        "campaign",
        "device_type",
        "platform",
        "landing_page",
    ], session_rows(sessions))
    write_insert(lines, "orders", ["order_id", "user_id", "session_id", "order_timestamp", "total_value", "payment_method", "order_status"], orders)
    write_insert(lines, "order_items", ["order_item_id", "order_id", "product_id", "quantity", "item_price", "discount_amount"], order_items)
    write_insert(lines, "reviews", ["review_id", "user_id", "product_id", "order_id", "rating", "review_length", "created_at"], reviews)
    write_insert(lines, "event_logs", [
        "event_id",
        "event_name",
        "event_timestamp",
        "event_date",
        "user_id",
        "session_id",
        "product_id",
        "category_id",
        "order_id",
        "review_id",
        "search_term",
        "list_id",
        "page_number",
        "quantity",
        "price",
        "items_count",
        "total_value",
        "payment_method",
        "rating",
        "review_length",
    ], sorted(event_logs, key=lambda row: row[0]))

    output_file.write_text("\n".join(lines), encoding="utf-8")

    print("Synthetic SQL seed data generated.")
    print(f"Output file: {output_file}")
    print(f"users: {len(users)}")
    print(f"categories: {len(categories)}")
    print(f"products: {len(products)}")
    print(f"sessions: {len(sessions)}")
    print(f"orders: {len(orders)}")
    print(f"order_items: {len(order_items)}")
    print(f"reviews: {len(reviews)}")
    print(f"event_logs: {len(event_logs)}")
    print("validation: passed")


if __name__ == "__main__":
    main()
