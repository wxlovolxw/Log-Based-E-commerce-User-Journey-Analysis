# Interview Project Script

## 1. 30초 요약

이 프로젝트는 사용자 행동 로그를 직접 설계한 이커머스 유저 여정 분석 프로젝트입니다. MySQL로 데이터 모델링과 정합성 검증을 수행하고, SQL로 퍼널, 구매 전환, 구매 이후 리뷰 행동을 분석했습니다. 이후 Python으로 세션 단위 feature dataset을 구성하고 Logistic Regression baseline 모델링을 수행했습니다. 분석 결과는 A/B 테스트 설계안과 Tableau 대시보드 설계안으로 연결했습니다. 데이터는 synthetic data 기반이므로 실제 서비스 성능을 주장하기보다, 이벤트 설계부터 분석, 모델링, 실험 및 대시보드 설계까지 이어지는 분석 파이프라인 검증에 초점을 두었습니다.

## 2. 1분 요약

이 프로젝트는 이커머스 사용자 행동 로그를 직접 설계하고, 구매 퍼널과 전환 행동을 end-to-end로 분석하는 흐름을 검증하기 위해 진행했습니다. 먼저 `session_start`, `view_item`, `add_to_cart`, `begin_checkout`, `purchase`, `review_write` 같은 이벤트와 `users`, `sessions`, `orders`, `reviews`, `event_logs` 등 주요 엔티티를 정의했습니다. 이후 MySQL schema를 작성하고 synthetic data를 적재한 뒤, 정합성 검증과 SQL 분석을 수행했습니다.

SQL 분석에서는 전체 구매 전환율이 28.2%였고, `add_to_cart` -> `begin_checkout` 전환율은 63.32%, 주문 대비 리뷰 작성률은 39.72%로 확인했습니다. Python에서는 `outputs/session_level_features.csv`를 기반으로 Logistic Regression baseline을 구성했고, 구매 직전 행동인 `begin_checkout` 관련 변수를 제외한 `without_checkout` 모델에서도 F1 0.8889, ROC-AUC 0.9834를 확인했습니다.

모델링 과정에서는 `session_duration_minutes`가 `purchase`, `review_write` 이벤트를 포함할 수 있는 leakage 가능성을 발견했고, 예측 시점 이전 행동 기준으로 재정의했습니다. 최종적으로 분석 결과를 장바구니 -> 결제 시작 전환 개선 A/B 테스트 설계안과 Tableau 대시보드 설계안으로 연결했습니다. 모든 결과는 synthetic data 기반이므로 실제 서비스 인사이트로 일반화하지 않고, 분석 파이프라인과 문제 해결 흐름을 검증한 결과로 해석했습니다.

## 3. 2분 상세 설명

### 3.1 문제 정의

이 프로젝트의 문제 정의는 이커머스 사용자 행동 로그를 기반으로 구매 퍼널의 이탈 구간과 구매 전환 관련 행동 신호를 파악하는 것입니다. 단순 CSV 분석이 아니라, 이벤트 로그 설계부터 데이터 모델링, SQL 분석, Python 모델링, 실험 설계, 대시보드 설계까지 이어지는 분석 흐름을 구성하는 데 초점을 두었습니다.

### 3.2 데이터 설계

데이터는 직접 설계한 synthetic data입니다. 주요 규모는 `users` 300명, `sessions` 1000개, `orders` 282건, `reviews` 112건, `event_logs` 5832건입니다. 이벤트는 `session_start`, `search`, `view_item_list`, `view_item`, `add_to_cart`, `begin_checkout`, `purchase`, `review_write`로 구성했고, 관계형 테이블은 `users`, `sessions`, `categories`, `products`, `orders`, `order_items`, `reviews`, `event_logs`로 설계했습니다.

### 3.3 SQL 분석

MySQL에서는 정합성 검증과 핵심 지표 산출을 담당했습니다. 사용자/세션 관계, 주문/구매 이벤트, 상품/카테고리, 리뷰 이벤트 등 주요 관계를 검증했고, quality check 위반 0건을 확인했습니다. SQL 분석 결과 전체 구매 전환율은 28.2%였고, 퍼널상 `add_to_cart` -> `begin_checkout` 전환율은 63.32%로 확인했습니다. 또한 구매 세션은 미구매 세션보다 평균 이벤트 수, 상품 조회 수, 장바구니 행동이 높게 나타났습니다.

### 3.4 Python 모델링

Python에서는 `outputs/session_level_features.csv`를 기반으로 세션 단위 feature dataset을 구성하고 Logistic Regression baseline을 수행했습니다. `with_checkout` 모델은 `begin_checkout_count`, `has_begin_checkout`을 포함했고, `without_checkout` 모델은 구매 직전 행동인 두 feature를 제외했습니다. `without_checkout` 모델에서도 F1 0.8889, ROC-AUC 0.9834가 나와, 결제 이전 행동 패턴만으로도 구매 전환 여부를 일정 수준 구분할 수 있음을 확인했습니다.

### 3.5 Feature Leakage 검토

초기 모델링 과정에서 `session_duration_minutes` 계수가 크게 나타났고, SQL 계산식을 확인하면서 `purchase`, `review_write` 이벤트가 duration 계산에 포함될 수 있는 가능성을 발견했습니다. 예측 시점 이전 행동 기준으로 사용하기 위해 `session_duration_minutes`를 `purchase`, `review_write` 제외 기준으로 재정의했고, 이후 모델 성능이 유지되는지 확인했습니다. 이 과정은 feature 정의를 보수적으로 검토한 사례입니다.

### 3.6 A/B 테스트 설계

분석 결과를 바탕으로 A/B 테스트 설계안을 작성했습니다. 1순위는 장바구니 -> 결제 시작 전환 개선입니다. `add_to_cart`는 모델링에서도 주요 신호였고, 퍼널상 `add_to_cart`에서 `begin_checkout`으로 넘어가는 구간이 개선 후보로 나타났기 때문입니다. 그 외 상품 탐색 -> 장바구니 추가 유도, 구매 후 리뷰 작성 유도를 후순위 실험 후보로 정리했습니다.

### 3.7 Tableau 대시보드 설계

Tableau는 실제 운영 대시보드가 아니라 분석 결과 전달 구조로 설계했습니다. Dashboard 1은 Funnel Overview, Dashboard 2는 Conversion Behavior Analysis, Dashboard 3은 Post-purchase & Experiment Design으로 구성했습니다. SQL 분석, Python 모델링, A/B 테스트 설계안을 하나의 흐름으로 설명할 수 있도록 KPI card, bar chart, table 중심의 단순하고 설명 가능한 구조로 정리했습니다.

### 3.8 한계와 확장 방향

가장 큰 한계는 synthetic data 기반이라는 점입니다. 실제 사용자 행동, 유입 채널, 캠페인, 디바이스, 가격/할인 정보, 사용자 세그먼트가 포함되어 있지 않으므로 실제 서비스 인사이트로 일반화할 수 없습니다. 확장 방향으로는 실제 로그 데이터 적용, 유입 채널/상품 카테고리/사용자 세그먼트별 drill-down, 실제 Tableau 구현, A/B 테스트 표본 크기 산정과 통계적 유의성 검정, Random Forest나 Gradient Boosting 같은 추가 모델 비교가 있습니다.

## 4. 예상 질문과 답변

### Q1. 왜 synthetic data를 사용했나요?

실제 서비스 로그는 접근이 어렵고 개인정보와 보안 이슈가 있습니다. 그래서 이 프로젝트에서는 실제 서비스 인사이트를 도출하기보다, 이벤트 구조, 엔티티 관계, 정합성 규칙, 분석 흐름을 직접 설계하는 데 초점을 두었습니다. synthetic data를 사용해 MySQL schema, 정합성 검증, SQL 분석, Python 모델링, 실험 설계까지 이어지는 분석 파이프라인을 구현하고 검증했습니다.

### Q2. SQL, Python, Tableau의 역할을 어떻게 나눴나요?

SQL은 원천 로그와 관계형 테이블에서 퍼널, 전환, 리뷰 지표를 산출하는 역할로 두었습니다. Python은 세션 단위 feature dataset 구성, 구매 전환 baseline 모델링, coefficient 해석을 담당했습니다. Tableau는 분석 결과를 대시보드 형태로 전달하기 위한 설계 역할로 정의했습니다. 역할을 분리해 분석 재현성과 결과 전달력을 높이는 구조로 구성했습니다.

### Q3. 왜 Logistic Regression을 baseline으로 사용했나요?

Logistic Regression은 세션 단위 행동 feature와 구매 전환 여부의 관계를 해석하기 쉽습니다. coefficient를 통해 어떤 행동 신호가 구매 전환 구분에 영향을 주는지 확인할 수 있고, 복잡한 모델보다 baseline으로 적합합니다. 이 프로젝트의 목적은 실제 성능 경쟁이 아니라 분석 흐름 검증이므로, 해석 가능한 baseline 모델이 적절하다고 판단했습니다.

### Q4. 왜 begin_checkout을 제외한 모델을 따로 만들었나요?

`begin_checkout`은 구매 직전 행동이라 구매 예측에 너무 강한 신호일 수 있습니다. 결제 직전 이벤트를 포함하면 사전 예측 관점에서 과도하게 낙관적인 모델이 될 수 있기 때문에, `with_checkout`과 `without_checkout` 모델을 나눠 비교했습니다. `without_checkout`에서도 F1 0.8889, ROC-AUC 0.9834로 성능이 유지되어, 결제 이전 행동 패턴의 설명 가능성을 확인했습니다.

### Q5. leakage 가능성은 어떻게 발견했고 어떻게 수정했나요?

초기 모델링에서 `session_duration_minutes` 계수가 크게 나타났습니다. 이후 SQL 계산식을 확인해 보니 `purchase`, `review_write` 이벤트까지 duration에 포함될 가능성이 있었습니다. 예측 시점 이전 행동 기준으로 사용하기 위해 `purchase`, `review_write`를 제외하고 duration을 재정의했습니다. 이후 모델을 재실행해 성능이 유지되는지 확인했습니다. 이 과정은 feature 정의를 보수적으로 검토한 사례입니다.

### Q6. 주요 분석 결과는 무엇인가요?

전체 구매 전환율은 28.2%였고, `add_to_cart` -> `begin_checkout` 전환율은 63.32%로 주요 개선 후보로 보았습니다. `begin_checkout` 도달 세션의 구매 전환율은 77.05%였고, 주문 대비 리뷰 작성률은 39.72%였습니다. `without_checkout` 모델에서는 `event_count`와 `has_add_to_cart`가 주요 양의 신호로 나타났습니다. 이를 바탕으로 장바구니 도달 이후 결제 시작으로 넘어가는 구간을 A/B 테스트 1순위 후보로 제안했습니다.

### Q7. 이 프로젝트의 한계는 무엇인가요?

가장 큰 한계는 synthetic data 기반이므로 실제 사용자 행동으로 일반화할 수 없다는 점입니다. 또한 유입 채널, 캠페인, 디바이스, 할인 정보, 사용자 세그먼트 등 실제 서비스에서 중요한 변수가 없습니다. A/B 테스트는 실제 수행이 아니라 설계안 수준이고, Tableau도 현재는 구현 완료가 아니라 설계안 단계입니다.

### Q8. 실제 서비스 데이터라면 무엇을 추가하고 싶나요?

실제 서비스 데이터라면 유입 채널, 캠페인, 디바이스, 사용자 세그먼트, 상품 카테고리, 가격/할인 정보를 추가하고 싶습니다. 이후 cohort 분석, retention 분석, 재구매 분석으로 확장할 수 있습니다. A/B 테스트 관점에서는 표본 크기 산정과 통계적 유의성 검정을 추가하고, Tableau에서는 기간/채널/카테고리별 drill-down 대시보드를 구현하고 싶습니다.

### Q9. 이 프로젝트에서 가장 잘한 점은 무엇인가요?

단순 CSV 분석이 아니라 이벤트 로그 설계부터 DB schema, 정합성 검증, SQL 분석, Python 모델링, 실험 설계, 대시보드 설계까지 연결한 점입니다. 특히 모델링 과정에서 leakage 가능성을 발견하고 feature 정의를 수정한 점이 의미 있었습니다. 또한 synthetic data 기반이라는 한계를 명확히 인식하고, 결과를 실제 서비스 성능으로 과장하지 않은 점도 중요합니다.

### Q10. 아쉬운 점은 무엇인가요?

실제 서비스 데이터가 아니라 synthetic data라는 점이 가장 아쉽습니다. 또한 실제 Tableau 구현과 실제 A/B 테스트 수행까지는 아직 진행하지 못했습니다. 향후 실제 로그 데이터와 유입 채널, 사용자 세그먼트 변수를 추가하면 분석 현실성이 높아질 수 있습니다.

## 5. 면접에서 피해야 할 표현

- "실제 이커머스 서비스에서 이런 인사이트가 나왔다"라고 말하지 않는다.
- "모델 성능이 높아서 실무 적용 가능하다"라고 단정하지 않는다.
- "A/B 테스트를 수행했다"라고 말하지 않는다.
- "Tableau 대시보드를 완성했다"라고 말하지 않는다.
- 대신 "synthetic data 기반으로 분석 파이프라인을 구현했다", "실험 설계안을 도출했다", "대시보드 설계안을 작성했다"라고 표현한다.

## 6. 면접에서 강조할 표현

- 이벤트 로그를 직접 설계했다.
- 정합성 검증 규칙을 SQL로 확인했다.
- 세션 단위 feature dataset을 구성했다.
- 구매 직전 이벤트를 제외한 모델도 비교했다.
- leakage 가능성을 발견하고 feature 정의를 수정했다.
- 분석 결과를 A/B 테스트 설계안과 Tableau 대시보드 설계안으로 연결했다.
- synthetic data 기반이므로 결과를 실제 서비스 성능으로 일반화하지 않았다.
