# Data Quality Rules

## 1. 문서 목적

이 문서는 로그 기반 이커머스 유저 여정 분석 프로젝트의 1차 정합성 검증 항목을 정리한다.

현재 단계에서는 검증 규칙만 정의하며, 실제 SQL 검증 쿼리는 작성하지 않는다.

## 2. 1차 정합성 검증 항목

### 2.1 사용자 및 세션 참조 정합성

| 검증 항목 | 설명 |
|---|---|
| `sessions.user_id`는 `users.user_id`에 존재해야 한다. | 세션은 유효한 사용자에 속해야 한다. |
| `event_logs.session_id`는 `sessions.session_id`에 존재해야 한다. | 이벤트는 유효한 세션에 속해야 한다. |
| `event_logs.user_id`는 `users.user_id`에 존재해야 한다. | 이벤트는 유효한 사용자에 속해야 한다. |
| `event_logs.user_id`는 동일 `session_id` 기준으로 `sessions.user_id`와 일치해야 한다. | 이벤트 로그의 사용자 중복 저장값이 세션의 사용자와 일치해야 한다. |

### 2.2 주문 참조 정합성

| 검증 항목 | 설명 |
|---|---|
| `orders.user_id`는 `users.user_id`에 존재해야 한다. | 주문은 유효한 사용자에 속해야 한다. |
| `orders.session_id`는 `sessions.session_id`에 존재해야 한다. | 주문은 유효한 세션에 연결되어야 한다. |
| `orders.user_id`는 동일 `session_id` 기준으로 `sessions.user_id`와 일치해야 한다. | 주문 사용자와 세션 사용자가 일치해야 한다. |

### 2.3 구매 이벤트와 주문 정합성

| 검증 항목 | 설명 |
|---|---|
| `event_logs`에서 `event_name = 'purchase'`인 경우, `order_id`는 `orders.order_id`에 존재해야 한다. | 구매 이벤트는 실제 주문과 연결되어야 한다. |
| `purchase` 이벤트의 `user_id`는 `orders.user_id`와 일치해야 한다. | 구매 이벤트 사용자와 주문 사용자가 일치해야 한다. |
| `purchase` 이벤트의 `session_id`는 `orders.session_id`와 일치해야 한다. | 구매 이벤트 세션과 주문 세션이 일치해야 한다. |

## 3. 후속 검증 항목 후보

다음 단계에서는 상품, 카테고리, 주문 상품, 리뷰 관련 정합성 검증 항목을 추가한다.

- `products.category_id`와 `categories.category_id` 참조 정합성
- 상품 관련 이벤트의 `product_id`와 `products.product_id` 참조 정합성
- `order_items.order_id`와 `orders.order_id` 참조 정합성
- `order_items.product_id`와 `products.product_id` 참조 정합성
- `reviews.user_id`, `reviews.product_id`, `reviews.order_id` 참조 정합성
- 리뷰 작성 사용자가 주문 사용자와 일치하는지 여부
