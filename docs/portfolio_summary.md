# Log-Based E-commerce User Journey Analysis Portfolio Summary

## 1. 프로젝트 개요

- 프로젝트명: 로그 기반 이커머스 유저 여정 분석
- 목적:
  - 이커머스 사용자 행동 로그를 직접 설계하고, MySQL 기반 데이터 모델링과 정합성 검증을 수행한다.
  - SQL로 퍼널, 구매 전환, 구매 이후 리뷰 행동을 분석한다.
  - Python으로 세션 단위 feature dataset을 구성하고 구매 전환 예측 baseline 모델링을 수행한다.
  - 분석 결과를 바탕으로 A/B 테스트 설계안과 Tableau 대시보드 설계안까지 연결한다.
- 데이터:
  - 직접 설계한 synthetic data
  - `users` 300명, `sessions` 1000개, `orders` 282건, `order_items` 558건, `reviews` 112건, `event_logs` 5832건
- 주의:
  - 실제 서비스 데이터가 아니므로 결과를 실제 서비스 인사이트로 일반화하지 않는다.

## 2. 분석 질문

이 프로젝트는 다음 질문을 중심으로 진행했다.

1. 사용자는 구매 퍼널의 어느 단계에서 가장 많이 이탈하는가?
2. 어떤 세션 행동이 구매 전환과 관련이 있는가?
3. 구매 직전 행동을 제외해도 결제 이전 행동만으로 구매 전환 여부를 구분할 수 있는가?
4. 구매 이후 리뷰 작성 행동은 어떤 패턴을 보이는가?
5. 분석 결과를 바탕으로 어떤 A/B 테스트 설계안을 도출할 수 있는가?
6. SQL, Python, Tableau가 각각 어떤 역할로 분석 흐름을 구성하는가?

## 3. 분석 흐름

1. 이벤트/엔티티 설계
   - 이벤트: `session_start`, `search`, `view_item_list`, `view_item`, `add_to_cart`, `begin_checkout`, `purchase`, `review_write`
   - 엔티티: `users`, `sessions`, `categories`, `products`, `orders`, `order_items`, `reviews`, `event_logs`
2. MySQL schema 및 seed data 구축
   - MySQL 물리 스키마를 작성하고, 쿼리 검증용 seed data와 분석 확장용 synthetic data를 구성했다.
3. 정합성 검증
   - 사용자/세션, 주문/구매, 상품/카테고리, 리뷰 이벤트 등 핵심 관계를 검증했다.
   - quality check 위반 0건을 확인했다.
4. SQL 분석
   - 퍼널 분석
   - 구매/미구매 세션 행동 비교
   - 행동 도달 여부별 구매 전환율
   - 장바구니 횟수 구간별 구매 전환율
   - 구매 후 리뷰 작성률 및 리뷰 세션 유형 분석
5. Python 모델링
   - `outputs/session_level_features.csv`를 생성했다.
   - `scripts/model_logistic_regression.py`로 Logistic Regression baseline을 수행했다.
   - `with_checkout`, `without_checkout` 모델을 비교했다.
6. Leakage 검토
   - `session_duration_minutes`가 `purchase`, `review_write`를 포함할 수 있음을 발견했다.
   - 예측 시점 이전 행동 기준으로 feature 정의를 재정의했다.
7. A/B 테스트 설계안
   - 장바구니 -> 결제 시작 전환 개선
   - 상품 탐색 -> 장바구니 추가 유도
   - 구매 후 리뷰 작성 유도
8. Tableau 대시보드 설계안
   - Funnel Overview
   - Conversion Behavior Analysis
   - Post-purchase & Experiment Design

## 4. 핵심 결과

### SQL 분석 결과

- 전체 세션 수: 1000
- `purchase` 도달 세션 수: 282
- 전체 구매 전환율: 28.2%

퍼널 도달 세션 수:

| 퍼널 단계 | 도달 세션 수 |
|---|---:|
| `session_start` | 1000 |
| `view_item` | 867 |
| `add_to_cart` | 578 |
| `begin_checkout` | 366 |
| `purchase` | 282 |

직전 단계 전환율:

| 퍼널 단계 | 직전 단계 전환율 |
|---|---:|
| `view_item` | 86.70% |
| `add_to_cart` | 66.67% |
| `begin_checkout` | 63.32% |
| `purchase` | 77.05% |

구매/미구매 세션 비교:

| 지표 | 구매 세션 평균 | 미구매 세션 평균 |
|---|---:|---:|
| 이벤트 수 | 9.68 | 4.32 |
| 상품 조회 수 | 3.10 | 1.66 |
| 장바구니 수 | 1.98 | 0.61 |

행동 도달 여부별 구매 전환율:

| 행동 도달 기준 | 구매 전환율 |
|---|---:|
| `add_to_cart` 도달 세션 | 48.79% |
| `begin_checkout` 도달 세션 | 77.05% |

리뷰:

| 지표 | 값 |
|---|---:|
| 전체 주문 수 | 282 |
| 리뷰 작성 주문 수 | 112 |
| 리뷰 작성률 | 39.72% |
| `same_purchase_session` | 66.07% |
| `separate_post_purchase_session` | 33.93% |

### Python 모델링 결과

| 모델 | 설명 | F1 | ROC-AUC |
|---|---|---:|---:|
| `with_checkout` | `begin_checkout_count`, `has_begin_checkout` 포함 | 0.9032 | 0.9838 |
| `without_checkout` | 구매 직전 행동인 `begin_checkout_count`, `has_begin_checkout` 제외 | 0.8889 | 0.9834 |

`without_checkout` 모델에서도 높은 구분 성능이 유지되어, 구매 직전 행동인 `begin_checkout` 없이도 결제 이전 세션 행동 패턴이 구매 전환 여부를 구분하는 데 활용될 수 있음을 확인했다. 단, synthetic data 기반 결과이므로 실제 서비스 예측 성능으로 일반화하지 않는다.

## 5. 주요 해석

- 퍼널상 `add_to_cart` -> `begin_checkout` 구간은 주요 개선 후보로 볼 수 있다.
- 구매 세션은 미구매 세션보다 평균 이벤트 수, 상품 조회 수, 장바구니 행동이 높게 나타났다.
- `begin_checkout`을 제외한 모델에서도 `event_count`와 `has_add_to_cart`가 주요 양의 신호로 나타났다.
- 일부 세부 행동 횟수 변수는 음의 계수를 보였으나, 이는 `event_count` 등과 정보가 중복되며 계수 부호가 분산된 결과로 해석했다.
- 개별 coefficient의 부호를 단독으로 해석하기보다 전체 행동량과 장바구니 도달 여부가 구매 전환을 구분하는 핵심 신호라는 점에 초점을 두었다.
- `session_duration_minutes`의 leakage 가능성을 발견하고 feature 정의를 수정한 과정은 모델링 결과 해석의 신뢰도를 높이는 단계였다.
- A/B 테스트 설계안에서는 장바구니 -> 결제 시작 전환 개선을 1순위 실험 후보로 제안했다.

## 6. 사용 기술

- SQL / MySQL Workbench
- Python
- pandas
- scikit-learn
- matplotlib
- Jupyter Notebook
- Tableau 설계
- Git / GitHub
- Codex 활용

## 7. 포트폴리오에서 강조할 점

- 단순 EDA가 아니라, 이벤트 로그 설계부터 DB schema, 정합성 검증, SQL 분석, Python 모델링, 실험 설계, 대시보드 설계까지 연결한 end-to-end 분석 프로젝트이다.
- synthetic data라는 한계를 명확히 인식하고, 실제 서비스 인사이트가 아니라 분석 파이프라인 검증으로 포지셔닝했다.
- 모델링 과정에서 leakage 가능성을 발견하고 SQL feature 정의를 수정했다.
- 구매 직전 행동을 제외한 모델을 별도로 구성하여, 더 보수적인 관점에서 구매 전환 행동 신호를 확인했다.
- 분석 결과를 A/B 테스트 설계안과 Tableau 대시보드 설계안으로 연결했다.

## 8. 한계와 확장 방향

### 한계

- synthetic data 기반이므로 실제 사용자 행동으로 일반화할 수 없다.
- 유입 채널, 마케팅 캠페인, 사용자 세그먼트, 디바이스, 상품 가격 할인 정보 등이 없다.
- 실제 A/B 테스트를 수행한 것이 아니라 설계안까지만 작성했다.

### 확장 방향

- 실제 서비스 로그 데이터 적용
- 유입 채널/상품 카테고리/사용자 세그먼트별 funnel drill-down
- Tableau 실제 대시보드 구현
- 실험 표본 크기 산정 및 통계적 유의성 검정 추가
- Random Forest, Gradient Boosting 등 추가 모델과 해석 비교

## 9. 면접 설명용 1분 요약

이 프로젝트는 이커머스 사용자 행동 로그를 직접 설계하고, MySQL 기반 스키마와 synthetic data를 구성한 뒤, 정합성 검증부터 SQL 분석, Python 모델링, A/B 테스트 설계, Tableau 대시보드 설계까지 연결한 end-to-end 분석 프로젝트이다. SQL에서는 구매 퍼널, 구매/미구매 세션 행동 차이, 구매 이후 리뷰 행동을 분석했고, Python에서는 세션 단위 feature dataset을 기반으로 Logistic Regression baseline을 구성했다. 특히 구매 직전 행동인 `begin_checkout` 관련 변수를 제외한 모델에서도 F1 0.8889, ROC-AUC 0.9834의 구분 성능을 확인하여, 결제 이전 행동량과 장바구니 도달 여부가 구매 전환을 구분하는 주요 신호임을 확인했다. 또한 `session_duration_minutes`의 target leakage 가능성을 발견하고 feature 정의를 수정했으며, 분석 결과를 장바구니 -> 결제 시작 전환 개선 A/B 테스트 설계안과 Tableau 대시보드 전달 구조로 확장했다. 다만 모든 결과는 synthetic data 기반이므로 실제 서비스 인사이트가 아니라 분석 파이프라인과 문제 해결 흐름을 검증한 결과로 해석한다.
