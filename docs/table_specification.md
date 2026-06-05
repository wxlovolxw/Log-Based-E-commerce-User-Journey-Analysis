# Table Specification

## 1. 문서 목적

이 문서는 로그 기반 이커머스 유저 여정 분석 프로젝트의 논리적 테이블 명세서다.

MySQL `schema.sql` 작성 전 단계의 사람용 설계 문서이며, 실제 `CREATE TABLE` SQL은 아직 작성하지 않는다. 앞서 정의한 이벤트, 엔티티, 관계, 정합성 검증 규칙을 바탕으로 각 테이블의 역할, 컬럼, 키, nullable 여부, 데이터 타입 후보를 정리한다.

## 2. 설계 기준

- DBMS는 MySQL을 기준으로 한다.
- 이벤트 로그는 1차 설계에서 단일 `event_logs` 테이블로 관리한다.
- 이벤트별 파라미터는 `event_logs`의 nullable 컬럼으로 관리한다.
- 사용자 단위 분석 편의를 위해 `event_logs`에는 `user_id`와 `session_id`를 모두 저장한다.
- 상세 정보는 `users`, `sessions`, `products`, `orders`, `reviews` 등 별도 엔티티 테이블에서 관리한다.
- 정합성 검증 규칙은 `docs/data_quality_rules.md`에서 별도로 관리한다.
- `event_logs`는 단일 로그 테이블이므로 nullable 컬럼이 많아질 수 있으며, 이는 초기 SQL 분석과 퍼널 분석의 단순성을 우선한 선택이다.
- 이벤트 종류나 파라미터가 확장될 경우 `event_params` 또는 이벤트별 상세 테이블 분리를 검토할 수 있다.

## 3. 테이블별 명세

### users

#### 역할

서비스를 이용하는 사용자를 관리한다. 사용자 단위 행동 분석과 세션, 주문, 리뷰 연결의 기준이 된다.

| column | type | key | nullable | description |
|---|---|---|---|---|
| `user_id` | `VARCHAR(50)` | PK | N | 사용자 식별자 |
| `signup_date` | `DATE` | - | Y | 가입일 |
| `user_type` | `VARCHAR(20)` | - | N | 회원/비회원 또는 신규/기존 사용자 구분 |
| `age_group` | `VARCHAR(20)` | - | Y | 연령대. exact age 대신 범주형으로 관리 |
| `gender` | `VARCHAR(20)` | - | Y | 성별. 분석 목적상 선택 속성 |

### sessions

#### 역할

사용자의 방문 단위를 관리한다. 유입 경로, 기기, 플랫폼, 랜딩 페이지 기준의 세션 분석에 사용한다.

| column | type | key | nullable | description |
|---|---|---|---|---|
| `session_id` | `VARCHAR(50)` | PK | N | 세션 식별자 |
| `user_id` | `VARCHAR(50)` | FK | N | 세션을 발생시킨 사용자 |
| `session_start_time` | `DATETIME` | - | N | 세션 시작 시각 |
| `session_end_time` | `DATETIME` | - | Y | 세션 종료 시각 |
| `traffic_source` | `VARCHAR(50)` | - | Y | 유입 출처 |
| `medium` | `VARCHAR(50)` | - | Y | 유입 매체 |
| `campaign` | `VARCHAR(100)` | - | Y | 캠페인명 |
| `device_type` | `VARCHAR(30)` | - | Y | 기기 유형 |
| `platform` | `VARCHAR(30)` | - | Y | 웹/앱 구분 |
| `landing_page` | `VARCHAR(255)` | - | Y | 첫 진입 페이지 |

### event_logs

#### 역할

사용자 행동 이벤트를 단일 로그 테이블로 관리한다. 주요 퍼널 단계와 이벤트별 파라미터를 함께 저장해 초기 SQL 분석을 단순하게 수행할 수 있도록 한다.

`category_id`는 주로 `view_item_list`처럼 특정 상품이 아닌 카테고리/목록 단위 이벤트에서 사용한다. 상품 상세 조회나 장바구니 추가처럼 특정 상품을 참조하는 이벤트의 카테고리는 원칙적으로 `products.category_id`를 통해 확인한다.

`rating`, `review_length`는 `review_write` 이벤트 분석 편의를 위한 이벤트 파라미터이며, 리뷰 상세 정보의 기준 저장소는 `reviews` 테이블로 본다.

| column | type | key | nullable | description |
|---|---|---|---|---|
| `event_id` | `VARCHAR(50)` | PK | N | 이벤트 식별자 |
| `event_name` | `VARCHAR(50)` | - | N | 이벤트 이름 |
| `event_timestamp` | `DATETIME` | - | N | 이벤트 발생 시각 |
| `event_date` | `DATE` | - | N | 이벤트 발생 날짜 |
| `user_id` | `VARCHAR(50)` | FK | N | 이벤트를 발생시킨 사용자 |
| `session_id` | `VARCHAR(50)` | FK | N | 이벤트가 속한 세션 |
| `product_id` | `VARCHAR(50)` | FK | Y | 상품 관련 이벤트에서 참조하는 상품 |
| `category_id` | `VARCHAR(50)` | FK | Y | 상품 목록/카테고리 관련 이벤트에서 참조하는 카테고리 |
| `order_id` | `VARCHAR(50)` | FK | Y | 구매 이벤트에서 참조하는 주문 |
| `review_id` | `VARCHAR(50)` | FK | Y | 리뷰 작성 이벤트에서 참조하는 리뷰 |
| `search_term` | `VARCHAR(255)` | - | Y | 검색 이벤트의 검색어 |
| `list_id` | `VARCHAR(100)` | - | Y | 상품 목록 식별자 또는 목록 유형 |
| `page_number` | `INT` | - | Y | 검색/목록 페이지 번호 |
| `quantity` | `INT` | - | Y | 장바구니 추가 수량 |
| `price` | `DECIMAL(10,2)` | - | Y | 이벤트 발생 시점의 상품 가격 |
| `items_count` | `INT` | - | Y | 결제 시작 시점의 상품 개수 |
| `total_value` | `DECIMAL(12,2)` | - | Y | 결제/구매 관련 총 금액 |
| `payment_method` | `VARCHAR(30)` | - | Y | 결제 수단 |
| `rating` | `TINYINT` | - | Y | 리뷰 평점 |
| `review_length` | `INT` | - | Y | 리뷰 길이 |

### categories

#### 역할

상품 분류 체계를 관리한다. 상품, 목록 조회, 카테고리 탐색 분석의 기준이 된다.

| column | type | key | nullable | description |
|---|---|---|---|---|
| `category_id` | `VARCHAR(50)` | PK | N | 카테고리 식별자 |
| `category_name` | `VARCHAR(100)` | - | N | 카테고리명 |
| `parent_category_id` | `VARCHAR(50)` | FK | Y | 상위 카테고리 식별자 |

### products

#### 역할

판매 상품 정보를 관리한다. 상품 조회, 장바구니, 구매, 리뷰 분석에서 상품 속성을 연결하는 기준이 된다.

| column | type | key | nullable | description |
|---|---|---|---|---|
| `product_id` | `VARCHAR(50)` | PK | N | 상품 식별자 |
| `product_name` | `VARCHAR(255)` | - | N | 상품명 |
| `category_id` | `VARCHAR(50)` | FK | N | 상품이 속한 카테고리 |
| `brand` | `VARCHAR(100)` | - | Y | 브랜드명 |
| `price` | `DECIMAL(10,2)` | - | N | 현재 상품 가격 |
| `created_at` | `DATETIME` | - | Y | 상품 등록 시각 |
| `is_active` | `BOOLEAN` | - | N | 현재 판매 활성 여부 |

### orders

#### 역할

사용자의 주문 결과를 관리한다. 구매 전환, 매출, 결제 수단, 주문 상태 분석의 기준이 된다.

| column | type | key | nullable | description |
|---|---|---|---|---|
| `order_id` | `VARCHAR(50)` | PK | N | 주문 식별자 |
| `user_id` | `VARCHAR(50)` | FK | N | 주문한 사용자 |
| `session_id` | `VARCHAR(50)` | FK | N | 주문이 발생한 세션 |
| `order_timestamp` | `DATETIME` | - | N | 주문 발생 시각 |
| `total_value` | `DECIMAL(12,2)` | - | N | 주문 총액 |
| `payment_method` | `VARCHAR(30)` | - | Y | 결제 수단 |
| `order_status` | `VARCHAR(30)` | - | N | 주문 상태 |

### order_items

#### 역할

주문에 포함된 개별 상품 행을 관리한다. 주문 금액 검증, 상품별 구매 수량, 상품 단위 할인 분석에 사용한다.

| column | type | key | nullable | description |
|---|---|---|---|---|
| `order_item_id` | `VARCHAR(50)` | PK | N | 주문 상품 행 식별자 |
| `order_id` | `VARCHAR(50)` | FK | N | 주문 식별자 |
| `product_id` | `VARCHAR(50)` | FK | N | 상품 식별자 |
| `quantity` | `INT` | - | N | 구매 수량 |
| `item_price` | `DECIMAL(10,2)` | - | N | 구매 당시 상품 단가 |
| `discount_amount` | `DECIMAL(10,2)` | - | Y | 상품 단위 할인 금액 |

### reviews

#### 역할

구매 이후 작성된 상품 리뷰를 관리한다. 리뷰 작성 전환과 구매 상품 기준 리뷰 정합성 검증에 사용한다.

| column | type | key | nullable | description |
|---|---|---|---|---|
| `review_id` | `VARCHAR(50)` | PK | N | 리뷰 식별자 |
| `user_id` | `VARCHAR(50)` | FK | N | 리뷰 작성자 |
| `product_id` | `VARCHAR(50)` | FK | N | 리뷰 대상 상품 |
| `order_id` | `VARCHAR(50)` | FK | N | 리뷰와 연결된 주문 |
| `rating` | `TINYINT` | - | N | 리뷰 평점 |
| `review_length` | `INT` | - | Y | 리뷰 길이 |
| `created_at` | `DATETIME` | - | N | 리뷰 작성 시각 |

## 4. 다음 단계

- MySQL 기준 `sql/schema.sql` 작성
