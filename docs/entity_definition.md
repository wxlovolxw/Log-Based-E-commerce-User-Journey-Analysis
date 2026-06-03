# Entity Definition

## 1. 문서 목적

이 문서는 로그 기반 이커머스 유저 여정 분석 프로젝트에서 1차로 도출한 주요 엔티티와 각 엔티티의 역할, 주요 속성 초안을 정리한다.

현재 단계는 논리적 엔티티와 분석 관점의 속성을 정리하는 단계이며, 물리적 테이블 설계 단계가 아니므로 SQL DDL은 작성하지 않는다.

## 2. 1차 엔티티 목록

| 엔티티 | 역할 |
|---|---|
| `users` | 서비스를 이용하는 사용자를 식별하고 사용자 단위 행동 분석의 기준이 된다. |
| `sessions` | 사용자의 방문 단위를 표현하며 세션 기준 여정 재구성의 기준이 된다. |
| `categories` | 상품이 속한 분류 체계를 표현하며 카테고리별 탐색과 전환 분석에 사용된다. |
| `products` | 판매 상품을 표현하며 상품 조회, 장바구니, 구매, 리뷰 분석의 기준이 된다. |
| `orders` | 사용자의 주문 및 결제 완료 결과를 표현하며 구매 전환과 매출 분석의 기준이 된다. |
| `order_items` | 주문에 포함된 개별 상품 단위를 표현하며 주문별 상품 구성 분석에 사용된다. |
| `reviews` | 구매 이후 작성된 상품 리뷰를 표현하며 리뷰 작성률과 상품별 후기 분석에 사용된다. |

## 3. 엔티티별 주요 속성 초안

### 3.1 users

| 속성 | 설명 | 비고 |
|---|---|---|
| `user_id` | 사용자 식별자 | 주요 식별자 |
| `created_at` | 사용자 생성 또는 가입 시각 | 선택 속성 |
| `user_status` | 활성, 휴면, 탈퇴 등 사용자 상태 | 선택 속성 |
| `user_segment` | 사용자 세그먼트 | 분석용 선택 속성 |

### 3.2 sessions

| 속성 | 설명 | 비고 |
|---|---|---|
| `session_id` | 세션 식별자 | 주요 식별자 |
| `user_id` | 세션을 발생시킨 사용자 식별자 | `users.user_id` 참조 |
| `session_start_at` | 세션 시작 시각 | `session_start` 기준 |
| `session_end_at` | 세션 종료 시각 | 파생 가능 |
| `traffic_source` | 유입 소스 | 선택 속성 |
| `medium` | 유입 매체 | 선택 속성 |
| `campaign` | 캠페인 | 선택 속성 |
| `device_type` | 디바이스 유형 | 선택 속성 |
| `platform` | 접속 플랫폼 | 선택 속성 |
| `landing_page` | 세션 최초 진입 페이지 | 선택 속성 |

### 3.3 categories

| 속성 | 설명 | 비고 |
|---|---|---|
| `category_id` | 카테고리 식별자 | 주요 식별자 |
| `category_name` | 카테고리명 | 주요 속성 |
| `parent_category_id` | 상위 카테고리 식별자 | 계층 구조가 있을 때 사용 |
| `category_depth` | 카테고리 깊이 | 선택 속성 |

### 3.4 products

| 속성 | 설명 | 비고 |
|---|---|---|
| `product_id` | 상품 식별자 | 주요 식별자, 이벤트 파라미터 `item_id`와 매핑 |
| `item_name` | 상품명 | 주요 속성 |
| `category_id` | 상품이 속한 카테고리 식별자 | `categories.category_id` 참조 |
| `brand` | 브랜드 | 선택 속성 |
| `price` | 기준 판매가 | KRW 기준 |
| `product_status` | 판매중, 품절, 판매중지 등 상품 상태 | 선택 속성 |

### 3.5 orders

| 속성 | 설명 | 비고 |
|---|---|---|
| `order_id` | 주문 식별자 | 주요 식별자 |
| `user_id` | 주문 사용자 식별자 | `users.user_id` 참조 |
| `session_id` | 주문이 발생한 세션 식별자 | `sessions.session_id` 참조 |
| `order_timestamp` | 주문 완료 시각 | `purchase` 기준 |
| `order_date` | 주문 완료 날짜 | 일자별 집계용 |
| `order_value` | 주문 금액 | KRW 기준 |
| `order_status` | 결제 완료, 취소, 환불 등 주문 상태 | 선택 속성 |

### 3.6 order_items

| 속성 | 설명 | 비고 |
|---|---|---|
| `order_item_id` | 주문 상품 행 식별자 | 주요 식별자 후보 |
| `order_id` | 주문 식별자 | `orders.order_id` 참조 |
| `product_id` | 상품 식별자 | `products.product_id` 참조 |
| `quantity` | 주문 수량 | 1 이상 |
| `unit_price` | 상품 단가 | KRW 기준 |
| `item_amount` | 주문 상품 금액 | 수량과 단가 기준 산출 가능 |

### 3.7 reviews

| 속성 | 설명 | 비고 |
|---|---|---|
| `review_id` | 리뷰 식별자 | 주요 식별자 |
| `user_id` | 리뷰 작성 사용자 식별자 | `users.user_id` 참조 |
| `order_id` | 리뷰와 연결된 주문 식별자 | `orders.order_id` 참조 |
| `product_id` | 리뷰 대상 상품 식별자 | `products.product_id` 참조 |
| `rating` | 평점 | 정의된 평점 범위 필요 |
| `review_created_at` | 리뷰 작성 시각 | `review_write` 기준 |
| `review_length` | 리뷰 본문 길이 | 선택 속성 |
| `has_photo` | 사진 첨부 여부 | 선택 속성 |
| `has_video` | 영상 첨부 여부 | 선택 속성 |

## 4. 엔티티 간 관계 분석

이 섹션은 1차 엔티티 간 관계를 논리적으로 정리한 초안이다. 아직 물리적 테이블 설계 단계가 아니므로 외래 키 제약 조건이나 SQL DDL은 작성하지 않는다.

상품 식별자는 엔티티 관계에서는 `product_id`로 표기한다. 이벤트 정의서의 GA4 스타일 이벤트 파라미터 `item_id`는 상품 엔티티의 `product_id`에 매핑되는 값으로 본다.

| 관계 | 설명 | 참조 기준 | 비고 |
|---|---|---|---|
| `users` 1:N `sessions` | 한 사용자는 여러 세션을 가질 수 있다. | `sessions.user_id` -> `users.user_id` | 필수 관계 |
| `sessions` 1:N `event_logs` | 한 세션 안에는 여러 이벤트가 발생할 수 있다. | `event_logs.session_id` -> `sessions.session_id` | 필수 관계 |
| `users` 1:N `event_logs` | 한 사용자는 여러 이벤트를 발생시킬 수 있다. | `event_logs.user_id` -> `users.user_id` | `event_logs.user_id`는 분석 편의성을 위해 중복 저장하며 `sessions.user_id`와 정합성 검증이 필요하다. |
| `categories` 1:N `products` | 한 카테고리는 여러 상품을 가진다. | `products.category_id` -> `categories.category_id` | 상품 카테고리 분석 기준 |
| `products` 1:N `event_logs` | 한 상품은 여러 상품 관련 이벤트에서 참조될 수 있다. | `event_logs.product_id` -> `products.product_id` | 모든 이벤트가 `product_id`를 갖는 것은 아니므로 nullable 관계로 본다. |
| `users` 1:N `orders` | 한 사용자는 여러 주문을 할 수 있다. | `orders.user_id` -> `users.user_id` | 구매 사용자 분석 기준 |
| `sessions` 1:N `orders` | 한 세션에서 0개 이상의 주문이 발생할 수 있다. | `orders.session_id` -> `sessions.session_id` | 세션별 구매 전환 분석 기준 |
| `orders` 1:N `order_items` | 한 주문은 여러 주문 상품 행을 가진다. | `order_items.order_id` -> `orders.order_id` | 주문 상세 분석 기준 |
| `products` 1:N `order_items` | 한 상품은 여러 주문 상품 행에 포함될 수 있다. | `order_items.product_id` -> `products.product_id` | 상품별 구매 분석 기준 |
| `users` 1:N `reviews` | 한 사용자는 여러 리뷰를 작성할 수 있다. | `reviews.user_id` -> `users.user_id` | 리뷰 작성 사용자 분석 기준 |
| `products` 1:N `reviews` | 한 상품은 여러 리뷰를 받을 수 있다. | `reviews.product_id` -> `products.product_id` | 상품별 리뷰 분석 기준 |
| `orders` 1:N `reviews` | 한 주문에서 여러 상품 리뷰가 작성될 수 있다. | `reviews.order_id` -> `orders.order_id` | 주문 상품별 리뷰가 작성될 수 있음을 전제로 한다. |
