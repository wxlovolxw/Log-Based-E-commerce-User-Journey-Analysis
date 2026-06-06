# SQL Analysis Results

## 1. 문서 목적

이 문서는 로그 기반 이커머스 유저 여정 분석 프로젝트의 SQL 분석 결과를 정리한다.

현재 주요 분석 결과는 `sql/seed_synthetic_data.sql`로 생성한 synthetic data를 기준으로 정리한다. 기존 `sql/seed_data.sql` 기반 결과는 소규모 검증용 결과로, SQL 쿼리 구조와 분석 흐름을 확인하는 데 사용했다.

synthetic data 역시 실제 서비스 데이터가 아니므로, 아래 결과를 실제 서비스 인사이트로 일반화하지 않는다. 본 문서는 분석 쿼리가 더 큰 데이터에서도 정상적으로 작동하고, 해석 가능한 결과를 반환하는지 확인한 결과로 본다.

## 2. 첫 번째 분석 주제: 퍼널 분석

### 분석 질문

사용자는 구매 과정에서 어디서 가장 많이 이탈하는가?

### 사용 데이터 및 SQL 파일

- 데이터는 `sql/seed_synthetic_data.sql`로 생성한 synthetic data다.
- 분석 쿼리는 `sql/funnel_analysis.sql`을 사용했다.
- SQL은 MySQL Workbench에서 실행했다.

### 분석 기준

주요 구매 퍼널 단계는 다음 순서로 정의했다.

`session_start` -> `view_item` -> `add_to_cart` -> `begin_checkout` -> `purchase`

`purchase`까지 도달한 세션은 `completed`로 분류했다.

`review_write`는 구매 이후 행동이므로 구매 퍼널 이탈과 별도로 해석했다. `review_write`만 발생한 세션은 `post_purchase_activity`로 분류했다.

### 주요 결과

퍼널 단계별 도달 세션 수와 `session_start` 대비 도달률은 다음과 같다.

| funnel_stage | reached_session_count | session_start_reach_rate |
|---|---:|---:|
| `session_start` | 1000 | 100.00 |
| `view_item` | 867 | 86.70 |
| `add_to_cart` | 578 | 57.80 |
| `begin_checkout` | 366 | 36.60 |
| `purchase` | 282 | 28.20 |

직전 단계 대비 전환율은 다음과 같다.

| funnel_stage | previous_stage_conversion_rate |
|---|---:|
| `view_item` | 86.70 |
| `add_to_cart` | 66.67 |
| `begin_checkout` | 63.32 |
| `purchase` | 77.05 |

이탈 단계별 세션 수는 다음과 같다.

| stage | session_count |
|---|---:|
| `session_start` | 35 |
| `search` | 25 |
| `view_item_list` | 70 |
| `view_item` | 289 |
| `add_to_cart` | 212 |
| `begin_checkout` | 84 |
| `post_purchase_activity` | 3 |
| `completed` | 282 |

### 결과 해석

synthetic data 기준 가장 큰 이탈은 `view_item` 단계에서 발생했다.

상품 상세 조회까지 도달한 867개 세션 중 578개만 `add_to_cart`로 이어졌고, 289개 세션이 `view_item` 단계에서 멈췄다.

두 번째 큰 이탈은 `add_to_cart` 단계이며, 212개 세션이 장바구니 이후 `begin_checkout`으로 이어지지 않았다.

`post_purchase_activity`는 구매 이후 리뷰 작성 등 사후 행동 세션이므로 구매 퍼널 이탈과 별도로 해석한다.

### 한계

- 이 결과는 synthetic data 생성 규칙에 기반한 결과이므로 실제 서비스의 이탈 지점이나 전환율로 일반화할 수 없다.
- 현재 퍼널 분석은 세션 단위 이벤트 도달 여부를 기준으로 하며, 엄격한 시간 순서 기반 퍼널 분석은 아직 수행하지 않았다.

### 다음 분석 방향

- 시간 순서 기반 strict funnel 분석을 추가한다.
- 상품/카테고리별 퍼널 전환 흐름을 분석한다.
- 유입 경로별 이탈 단계 차이를 비교한다.

## 3. 두 번째 분석 주제: 구매 전환 관련 행동

### 분석 질문

어떤 행동이 구매 전환과 관련이 있는가?

### 사용 데이터 및 SQL 파일

- 데이터는 `sql/seed_synthetic_data.sql`로 생성한 synthetic data다.
- 분석 쿼리는 `sql/conversion_analysis.sql`을 사용했다.
- SQL은 MySQL Workbench에서 실행했다.

### 주요 결과

구매 완료 세션은 282건, 미구매 세션은 718건이다.

구매 여부별 평균 행동량은 다음과 같다.

| purchase_status | session_count | avg_total_event_count | avg_view_item_count | avg_add_to_cart_count | begin_checkout_rate | search_rate |
|---|---:|---:|---:|---:|---:|---:|
| `non_purchase` | 718 | 4.32 | 1.66 | 0.61 | 11.70 | 38.16 |
| `purchase` | 282 | 9.68 | 3.10 | 1.98 | 100.00 | 56.74 |

주요 이벤트 도달 여부별 구매 전환율은 다음과 같다.

| event_name | reached_event_flag | purchase_conversion_rate |
|---|---:|---:|
| `add_to_cart` | 1 | 48.79 |
| `add_to_cart` | 0 | 0.00 |
| `begin_checkout` | 1 | 77.05 |
| `begin_checkout` | 0 | 0.00 |
| `search` | 1 | 36.87 |
| `search` | 0 | 21.55 |
| `view_item` | 1 | 32.53 |
| `view_item` | 0 | 0.00 |

상품 상세 조회 수 구간별 구매 전환율은 다음과 같다.

| view_item_count_segment | purchase_conversion_rate |
|---|---:|
| `0` | 0.00 |
| `1` | 21.03 |
| `2+` | 36.75 |

장바구니 추가 수 구간별 구매 전환율은 다음과 같다.

| add_to_cart_count_segment | purchase_conversion_rate |
|---|---:|
| `0` | 0.00 |
| `1` | 41.50 |
| `2+` | 56.99 |

### 결과 해석

synthetic data 기준 구매 세션은 미구매 세션보다 평균 이벤트 수, 상품 상세 조회 수, 장바구니 추가 수가 높았다.

`add_to_cart`와 `begin_checkout`에 도달하지 않은 세션에서는 구매가 발생하지 않았다.

상품 조회 수와 장바구니 추가 수가 많을수록 구매 전환율이 높아지는 패턴이 확인되었다.

다만 이는 synthetic data 생성 규칙의 영향을 받으므로 실제 전환 요인으로 일반화하지 않는다.

### 한계

- 이벤트 도달 여부와 구매 전환 간의 관계는 상관 패턴이며, 인과 효과로 해석할 수 없다.
- synthetic data 생성 로직상 구매 세션이 더 많은 행동을 갖도록 설계되어 있으므로 실제 서비스 전환 요인으로 일반화할 수 없다.

### 다음 분석 방향

- 유입 경로, 디바이스, 플랫폼별 구매 전환 행동 차이를 비교한다.
- 상품 조회 수와 장바구니 추가 수를 더 세분화해 전환율 변화를 확인한다.
- Python 분석 단계에서 구매/미구매 세션의 행동량 분포를 시각화한다.

## 4. 세 번째 분석 주제: 구매 이후 사용자 행동

### 분석 질문

구매 이후 사용자는 어떤 행동을 하는가?

### 사용 데이터 및 SQL 파일

- 데이터는 `sql/seed_synthetic_data.sql`로 생성한 synthetic data다.
- 분석 쿼리는 `sql/post_purchase_analysis.sql`을 사용했다.
- SQL은 MySQL Workbench에서 실행했다.

### 주요 결과

synthetic data 기준 전체 주문 수는 282건이다.

리뷰가 작성된 주문 수는 112건이다.

주문 기준 리뷰 작성률은 39.72%다.

리뷰 세션 유형별 결과는 다음과 같다.

| review_session_type | review_count | review_type_rate |
|---|---:|---:|
| `same_purchase_session` | 74 | 66.07 |
| `separate_post_purchase_session` | 38 | 33.93 |

리뷰 작성까지 걸린 시간은 구매 직후 수 분 내 작성된 경우와, 수백~수만 분 뒤 별도 세션에서 작성된 경우로 나뉘었다.

같은 구매 세션에서 작성된 리뷰는 즉시 구매 이후 행동으로 볼 수 있다.

`separate_post_purchase_session`은 구매 이후 재방문 행동으로 볼 수 있다.

### 결과 해석

synthetic data 기준으로 구매 이후 리뷰 작성은 전체 주문의 39.72%에서 발생했다.

리뷰 중 66.07%는 구매와 같은 세션에서 작성되었고, 33.93%는 별도 구매 이후 세션에서 작성되었다.

이를 통해 구매 이후 행동 분석에서는 리뷰 작성 여부뿐 아니라 리뷰 작성 시점과 세션 유형을 함께 보는 것이 중요함을 확인했다.

### 한계

- 이 결과는 synthetic data 생성 규칙에 기반한 결과이므로 실제 서비스의 리뷰 작성률이나 재방문 리뷰 비율로 일반화할 수 없다.
- 본 결과는 구매 이후 행동 분석 쿼리가 더 큰 synthetic data에서도 정상적으로 작동하고, 리뷰 세션 유형을 구분할 수 있음을 확인한 결과로 해석한다.

### 다음 분석 방향

- 상품/카테고리별 리뷰 작성률과 평점 분석으로 확장한다.
- 리뷰 작성까지 걸린 시간을 구간화해 즉시 리뷰와 지연 리뷰를 비교한다.
- Python 분석 단계에서 리뷰 작성 지연 시간 분포를 시각화한다.
