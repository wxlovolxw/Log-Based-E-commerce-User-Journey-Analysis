# SQL Analysis Results

## 1. 문서 목적

이 문서는 로그 기반 이커머스 유저 여정 분석 프로젝트의 SQL 분석 결과를 정리한다.

이번 문서는 첫 번째 분석 주제인 퍼널 분석 결과를 다룬다. 사용한 SQL 파일은 `sql/funnel_analysis.sql`이다.

현재 데이터는 실제 서비스 데이터가 아니라 `sql/seed_data.sql`로 만든 샘플 데이터다. 따라서 결과는 실제 서비스 인사이트가 아니라, 분석 쿼리의 동작과 해석 가능성을 확인한 결과로 정리한다.

## 2. 분석 질문

사용자는 구매 과정에서 어디서 가장 많이 이탈하는가?

## 3. 사용 데이터 및 SQL 파일

- 데이터는 `sql/seed_data.sql`로 생성한 샘플 데이터다.
- 분석 쿼리는 `sql/funnel_analysis.sql`을 사용했다.
- SQL은 MySQL Workbench에서 실행했다.

## 4. 분석 기준

주요 구매 퍼널 단계는 다음 순서로 정의했다.

`session_start` -> `view_item` -> `add_to_cart` -> `begin_checkout` -> `purchase`

`purchase`까지 도달한 세션은 `completed`로 분류했다.

`review_write`는 구매 이후 행동이므로 구매 퍼널 이탈과 별도로 해석했다. `review_write`만 발생한 세션은 `post_purchase_activity`로 분류했다.

## 5. 주요 결과

이탈 단계별 세션 수는 다음과 같다.

| stage | session_count |
|---|---:|
| `search` | 1 |
| `view_item` | 1 |
| `add_to_cart` | 1 |
| `begin_checkout` | 1 |
| `completed` | 3 |
| `post_purchase_activity` | 1 |

## 6. 결과 해석

현재 샘플 데이터 기준 구매 완료 세션은 3건이다.

구매 이전 이탈은 `search`, `view_item`, `add_to_cart`, `begin_checkout` 단계에서 각각 1건씩 발생했다.

특정 이탈 단계가 두드러지게 높다고 해석하기보다는, 퍼널 분석 쿼리가 각 세션의 최종 도달 단계를 구분할 수 있음을 확인한 결과로 본다.

`post_purchase_activity`는 구매 이후 리뷰 작성만 발생한 세션이므로 구매 퍼널 이탈로 해석하지 않는다. 이 분류를 통해 구매 과정 이탈과 구매 이후 행동을 분리해서 볼 수 있다.

## 7. 한계

- 현재 데이터는 8개 세션으로 구성된 샘플 데이터이므로 실제 사용자 행동을 대표하지 않는다.
- 따라서 전환율이나 이탈률을 실제 서비스 의사결정 근거로 일반화할 수 없다.
- 현재 퍼널 분석은 세션 단위 이벤트 도달 여부를 기준으로 하며, 엄격한 시간 순서 기반 퍼널 분석은 아직 수행하지 않았다.

## 8. 다음 분석 방향

- 더 큰 synthetic data를 생성해 동일한 퍼널 분석 쿼리를 적용한다.
- 시간 순서 기반 strict funnel 분석을 추가한다.
- 유입 경로별 전환율, 상품/카테고리별 전환 흐름, 구매 이후 리뷰 작성 행동 분석으로 확장한다.

## 9. 두 번째 분석 주제: 구매 전환 관련 행동

### 분석 질문

어떤 행동이 구매 전환과 관련이 있는가?

### 사용 SQL

- `sql/conversion_analysis.sql`
- SQL은 MySQL Workbench에서 실행했다.
- 데이터는 `sql/seed_data.sql`로 생성한 샘플 데이터다.

### 주요 결과

구매 완료 세션은 3건, 미구매 세션은 5건이다.

구매 세션은 미구매 세션보다 평균 이벤트 수가 높았다.

| purchase_status | avg_total_event_count |
|---|---:|
| `non_purchase` | 3.00 |
| `purchase` | 9.33 |

구매 세션은 미구매 세션보다 평균 상품 조회 수와 장바구니 추가 수가 높았다.

| purchase_status | avg_view_item_count | avg_add_to_cart_count |
|---|---:|---:|
| `non_purchase` | 0.60 | 0.40 |
| `purchase` | 2.00 | 2.00 |

`begin_checkout` 도달률은 구매 세션 100.00%, 미구매 세션 20.00%였다.

주요 이벤트 도달 여부별 구매 전환율은 다음과 같이 확인되었다.

| event_name | reached_event_flag | purchase_conversion_rate |
|---|---:|---:|
| `add_to_cart` | 1 | 60.00 |
| `add_to_cart` | 0 | 0.00 |
| `begin_checkout` | 1 | 75.00 |
| `begin_checkout` | 0 | 0.00 |

상품 상세 조회 수가 2개 이상인 세션은 2건 모두 구매로 이어졌다.

장바구니 추가 수가 2회 이상인 세션은 2건 모두 구매로 이어졌다.

유입 경로별 구매 전환율은 `affiliate` 100.00%, `google` 66.67%로 나타났다. 다만 표본 수가 작아 실제 서비스 경향으로 일반화하지 않는다.

### 결과 해석

현재 샘플 데이터에서는 `view_item`, `add_to_cart`, `begin_checkout` 행동이 구매 완료와 함께 나타나는 주요 행동 후보로 확인된다.

특히 `add_to_cart`와 `begin_checkout`은 구매 전환과 직접적으로 연결되는 행동으로 볼 수 있다.

다만 현재 데이터는 샘플 데이터이므로 실제 서비스 인사이트로 일반화하지 않는다. 본 결과는 구매 전환 관련 행동 비교 쿼리가 정상적으로 작동함을 확인한 결과로 해석한다.

### 다음 분석 방향

- 세 번째 질문인 구매 이후 사용자의 행동 분석으로 이어간다.
- 이후 더 큰 synthetic data를 생성해 동일한 분석을 반복한다.
