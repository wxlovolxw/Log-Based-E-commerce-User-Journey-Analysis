# Tableau 대시보드 설계안

## 1. 문서 개요

본 문서는 로그 기반 이커머스 유저 여정 분석 결과를 Tableau로 전달하기 위한 대시보드 설계안이다.

SQL 분석 결과, Python 모델링 결과, A/B 테스트 설계안을 하나의 흐름으로 전달하는 것을 목표로 한다. 실제 Tableau 대시보드를 이미 구현한 것이 아니라, 구현 전에 어떤 지표와 차트를 어떤 화면에 배치할지 정리한 구현 가이드이자 포트폴리오 설명 자료이다.

현재 분석은 synthetic data 기반이므로 실제 서비스 운영 대시보드가 아니라, 분석 결과 전달용 대시보드 설계안으로 해석한다.

## 2. 대시보드 전체 구성

| Dashboard | 제목 | 목적 |
|---|---|---|
| Dashboard 1 | Funnel Overview | 구매 퍼널 단계별 도달, 전환, 이탈을 요약한다. |
| Dashboard 2 | Conversion Behavior Analysis | 구매 세션과 미구매 세션의 행동 차이 및 모델링 결과를 전달한다. |
| Dashboard 3 | Post-purchase & Experiment Design | 구매 이후 리뷰 행동과 A/B 테스트 설계안을 함께 전달한다. |

전체 전달 흐름은 다음과 같다.

1. 사용자가 어느 퍼널 단계에서 이탈하는지 확인한다.
2. 구매 전환과 관련된 세션 행동 신호를 확인한다.
3. 분석 결과를 바탕으로 향후 검증 가능한 A/B 테스트 설계안을 제안한다.

## 3. Dashboard 1: Funnel Overview

### 3.1 목적

사용자가 구매 퍼널의 어느 단계에서 이탈하는지 한눈에 확인한다.

### 3.2 사용 데이터

- `outputs/funnel_stage_conversion.csv`
- `outputs/funnel_drop_off_summary.csv`

### 3.3 핵심 지표

| 지표 | 값 |
|---|---:|
| `session_start` 도달 세션 수 | 1000 |
| `view_item` 도달 세션 수 | 867 |
| `add_to_cart` 도달 세션 수 | 578 |
| `begin_checkout` 도달 세션 수 | 366 |
| `purchase` 도달 세션 수 | 282 |
| 전체 구매 전환율 | 28.2% |

### 3.4 추천 차트

| 영역 | 차트 | 설명 |
|---|---|---|
| 상단 KPI | KPI card | 전체 구매 전환율, 가장 큰 이탈 구간을 표시한다. |
| 중앙 | 퍼널 단계별 도달 세션 수 bar chart | 각 퍼널 단계에 도달한 세션 수를 비교한다. |
| 중앙 | 직전 단계 전환율 line 또는 bar chart | 이전 단계 대비 다음 단계 전환율을 보여준다. |
| 하단 | 단계별 이탈 세션 수 bar chart | 어느 단계에서 이탈 세션이 많은지 확인한다. |

### 3.5 주요 해석

`add_to_cart` -> `begin_checkout` 구간이 주요 개선 후보이다. 장바구니에 도달한 사용자가 결제 시작 단계로 넘어가는 비율을 높이는 실험 설계가 우선 검토 대상이 될 수 있다.

## 4. Dashboard 2: Conversion Behavior Analysis

### 4.1 목적

구매 세션과 미구매 세션의 행동 차이와 구매 전환 관련 행동 신호를 확인한다.

### 4.2 사용 데이터

- `outputs/conversion_behavior_by_purchase_status.csv`
- `outputs/conversion_rate_by_event_reach.csv`
- `outputs/conversion_rate_by_add_to_cart_segment.csv`
- `outputs/model_logistic_regression_metrics.csv`
- `outputs/model_logistic_regression_coefficients_without_checkout.csv`

### 4.3 추천 차트

| 영역 | 차트 | 설명 |
|---|---|---|
| 상단 | 구매/미구매 세션 평균 `event_count` 비교 bar chart | 구매 여부별 전체 행동량 차이를 보여준다. |
| 상단 | 구매/미구매 세션 평균 `view_item_count`, `add_to_cart_count` grouped bar chart | 상품 조회 및 장바구니 행동 차이를 비교한다. |
| 중앙 | 행동 도달 여부별 구매 전환율 bar chart | 특정 행동 도달 여부와 구매 전환율의 관계를 보여준다. |
| 중앙 | 장바구니 횟수 구간별 구매 전환율 bar chart | 장바구니 행동 강도와 구매 전환율을 비교한다. |
| 하단 | Logistic Regression 모델 성능 요약 table | `with_checkout`, `without_checkout` 모델 성능을 요약한다. |
| 하단 | `without_checkout` coefficient 상위 feature table | 구매 직전 행동을 제외한 모델의 주요 feature를 표시한다. |

### 4.4 주요 해석

- 구매 세션은 미구매 세션보다 평균 이벤트 수, 상품 조회 수, 장바구니 행동이 많다.
- `begin_checkout` 제외 모델에서도 F1 0.8889, ROC-AUC 0.9834로 구매 전환 여부를 구분했다.
- `event_count`와 `has_add_to_cart`가 주요 신호로 나타났다.
- coefficient는 feature 중복 가능성이 있으므로 개별 부호보다 전체 행동량과 장바구니 도달 여부 중심으로 해석한다.

### 4.5 표시 주의

모델링 결과는 실제 운영 예측 성능이 아니라 분석 흐름 검증 결과로 표기한다. 특히 synthetic data 기반 결과이므로 실제 서비스 구매 전환 예측 성능으로 일반화하지 않는다.

## 5. Dashboard 3: Post-purchase & Experiment Design

### 5.1 목적

구매 이후 리뷰 행동과 분석 기반 A/B 테스트 설계안을 함께 전달한다.

### 5.2 사용 데이터

- `outputs/post_purchase_review_session_type_share.csv`
- `docs/ab_test_design.md`의 설계안 요약
- 필요 시 리뷰 관련 SQL 결과 CSV

### 5.3 핵심 지표

| 지표 | 값 |
|---|---:|
| 전체 주문 수 | 282 |
| 리뷰 작성 주문 수 | 112 |
| 리뷰 작성률 | 39.72% |
| `same_purchase_session` 리뷰 비율 | 66.07% |
| `separate_post_purchase_session` 리뷰 비율 | 33.93% |

### 5.4 추천 차트

| 영역 | 차트 | 설명 |
|---|---|---|
| 상단 | 리뷰 작성률 KPI card | 전체 주문 대비 리뷰 작성률을 표시한다. |
| 중앙 | 리뷰 작성 세션 유형 비율 bar 또는 pie chart | 같은 구매 세션과 별도 구매 이후 세션의 리뷰 작성 비율을 비교한다. |
| 중앙 | 리뷰 작성 지연 시간 요약 table | 리뷰 작성 시점 관련 지표가 준비된 경우 요약한다. |
| 하단 | A/B 테스트 우선순위 table | 분석 결과 기반 실험 설계안의 우선순위를 표시한다. |

### 5.5 A/B 테스트 요약

| 우선순위 | 실험안 | 핵심 목적 |
|---:|---|---|
| 1 | 장바구니 -> 결제 시작 전환 개선 | `add_to_cart` 도달 세션의 `begin_checkout` 전환율 개선 |
| 2 | 상품 탐색 -> 장바구니 추가 유도 | `view_item` 도달 세션의 `add_to_cart` 전환율 개선 |
| 3 | 구매 후 리뷰 작성 유도 | 주문 대비 리뷰 작성률 개선 |

### 5.6 주요 해석

구매 전환 개선 관점에서는 장바구니 -> 결제 시작 전환 개선 실험이 우선순위가 높다. 리뷰 작성 유도 실험은 구매 이후 행동 개선 목적의 별도 실험으로 구분해 전달한다.

## 6. Tableau 구현 메모

- CSV 파일을 각각 Tableau 데이터 소스로 연결한다.
- 공통 필터로 `event_date` 또는 session segment를 둘 수 있으나, 현재 synthetic data에서는 필터 활용 범위가 제한적이다.
- KPI card, bar chart, table 중심으로 단순하고 설명 가능한 대시보드로 구성한다.
- 모델링 결과는 실제 운영 예측 성능이 아니라 분석 흐름 검증 결과로 표기한다.
- `docs/ab_test_design.md`의 실험 설계안은 Tableau 내 table 또는 텍스트 박스로 요약해 전달한다.
- 대시보드별 제목과 설명에는 synthetic data 기반 분석이라는 한계를 명시한다.

## 7. 한계

- synthetic data 기반이므로 실제 서비스 지표로 일반화하지 않는다.
- Tableau 대시보드는 분석 결과 전달용 설계안이며, 실제 운영 모니터링 대시보드가 아니다.
- 실제 서비스 적용 시 기간 필터, 유입 채널, 사용자 세그먼트, 상품 카테고리별 drill-down이 추가되어야 한다.
- 실제 운영 대시보드로 확장하려면 데이터 갱신 주기, 지표 정의서, 사용자 권한, 대시보드 성능 최적화 기준을 추가로 정의해야 한다.
