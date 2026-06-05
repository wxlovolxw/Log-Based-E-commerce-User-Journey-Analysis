# Data Quality Rules

## 1. 문서 목적

이 문서는 로그 기반 이커머스 유저 여정 분석 프로젝트에서 분석 전 확인해야 할 데이터 정합성 검증 항목을 정리한다.

현재 단계에서는 검증 규칙만 정의하며, 실제 SQL 검증 쿼리는 작성하지 않는다.

## 2. 정합성 검증 항목 1차

### 2.1 사용자 및 세션 참조 정합성

| 검증 항목 | 설명 |
|---|---|
| `sessions.user_id`는 `users.user_id`에 존재해야 한다. | 세션은 유효한 사용자에 속해야 한다. |
| `event_logs.session_id`는 `sessions.session_id`에 존재해야 한다. | 이벤트는 유효한 세션에 속해야 한다. |
| `event_logs.user_id`는 `users.user_id`에 존재해야 한다. | 이벤트는 유효한 사용자에 의해 발생해야 한다. |
| 동일 `session_id` 기준으로 `event_logs.user_id`는 `sessions.user_id`와 일치해야 한다. | 이벤트 로그의 사용자 값과 세션의 사용자 값이 일관되어야 한다. |

### 2.2 주문 참조 정합성

| 검증 항목 | 설명 |
|---|---|
| `orders.user_id`는 `users.user_id`에 존재해야 한다. | 주문은 유효한 사용자에 속해야 한다. |
| `orders.session_id`는 `sessions.session_id`에 존재해야 한다. | 주문은 유효한 세션과 연결되어야 한다. |
| 동일 `session_id` 기준으로 `orders.user_id`는 `sessions.user_id`와 일치해야 한다. | 주문 사용자와 세션 사용자가 일치해야 한다. |

### 2.3 구매 이벤트와 주문 정합성

| 검증 항목 | 설명 |
|---|---|
| `event_logs`에서 `event_name = 'purchase'`인 경우, `order_id`는 `orders.order_id`에 존재해야 한다. | 구매 이벤트는 실제 주문과 연결되어야 한다. |
| `purchase` 이벤트의 `user_id`는 `orders.user_id`와 일치해야 한다. | 구매 이벤트 사용자와 주문 사용자가 일치해야 한다. |
| `purchase` 이벤트의 `session_id`는 `orders.session_id`와 일치해야 한다. | 구매 이벤트 세션과 주문 세션이 일치해야 한다. |

## 3. 정합성 검증 항목 2차

### 3.1 상품-카테고리 정합성

| 검증 항목 | 설명 |
|---|---|
| `products.category_id`는 `categories.category_id`에 존재해야 한다. | 상품은 실제 존재하는 카테고리에 속해야 한다. |

### 3.2 이벤트-상품 정합성

| 검증 항목 | 설명 |
|---|---|
| 상품 관련 `event_logs.product_id`는 `products.product_id`에 존재해야 한다. | 상품 관련 이벤트는 실제 존재하는 상품을 참조해야 한다. |
| 모든 이벤트가 `product_id`를 갖는 것은 아니므로 `view_item`, `add_to_cart`, `review_write` 등 상품 관련 이벤트에 적용한다. | 상품 참조 검증은 상품 맥락이 있는 이벤트로 한정한다. |

### 3.3 주문상품 정합성

| 검증 항목 | 설명 |
|---|---|
| `order_items.order_id`는 `orders.order_id`에 존재해야 한다. | 주문 상품 행은 실제 주문에 속해야 한다. |
| `order_items.product_id`는 `products.product_id`에 존재해야 한다. | 주문 상품 행은 실제 상품을 참조해야 한다. |
| `orders.total_value`는 `order_items` 기준 계산 금액과 일관되어야 한다. | 주문 총액은 주문 상품 금액 집계와 일관되어야 한다. |
| 배송비, 쿠폰, 포인트, 세금 정책은 아직 정의하지 않았으므로 상세 계산식은 보류한다. | 금액 정합성의 상세 산식은 정책 정의 이후 확정한다. |

### 3.4 리뷰 정합성

| 검증 항목 | 설명 |
|---|---|
| `reviews.user_id`는 `users.user_id`에 존재해야 한다. | 리뷰는 유효한 사용자가 작성해야 한다. |
| `reviews.product_id`는 `products.product_id`에 존재해야 한다. | 리뷰는 실제 상품을 대상으로 작성되어야 한다. |
| `reviews.order_id`는 `orders.order_id`에 존재해야 한다. | 리뷰는 실제 주문과 연결되어야 한다. |
| `reviews.user_id`는 `orders.user_id`와 일치해야 한다. | 리뷰 작성자와 주문 사용자가 일치해야 한다. |
| `reviews`의 `(order_id, product_id)` 조합은 `order_items(order_id, product_id)`에 존재해야 한다. | 리뷰는 실제 구매한 상품에 대해서만 작성되어야 한다. |

### 3.5 리뷰 이벤트와 리뷰 테이블 정합성

| 검증 항목 | 설명 |
|---|---|
| `event_logs`에서 `event_name = 'review_write'`인 경우 `review_id`는 `reviews.review_id`에 존재해야 한다. | 리뷰 작성 이벤트는 실제 리뷰 레코드와 연결되어야 한다. |
| `review_write` 이벤트의 `user_id`는 `reviews.user_id`와 일치해야 한다. | 리뷰 이벤트 사용자와 리뷰 작성자가 일치해야 한다. |
| `review_write` 이벤트의 `product_id`는 `reviews.product_id`와 일치해야 한다. | 리뷰 이벤트 상품과 리뷰 대상 상품이 일치해야 한다. |
| `review_write` 이벤트의 `order_id`는 `reviews.order_id`와 일치해야 한다. | 리뷰 이벤트 주문과 리뷰 연결 주문이 일치해야 한다. |

## 4. 다음 단계

- 1차와 2차 정합성 검증 규칙을 기준으로 MySQL 검증 쿼리 작성 범위를 결정한다.
- 실제 검증 SQL은 물리 스키마 작성 이후 별도 단계에서 작성한다.
