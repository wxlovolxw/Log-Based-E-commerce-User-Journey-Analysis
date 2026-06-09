# Python Visualization Plan

## 1. 목적

이 문서는 SQL 분석 결과를 Python notebook에서 시각화하기 위한 작업 계획을 정리한다.

진행 방식은 다음과 같다.

1. MySQL Workbench에서 SQL 분석 결과를 CSV로 export한다.
2. CSV 파일을 `outputs/` 폴더에 저장한다.
3. `notebooks/01_user_journey_conversion_analysis.ipynb`에서 CSV를 불러온다.
4. Python으로 주요 분석 결과를 시각화한다.

현재 단계에서는 코드 작성 전 계획만 정리한다.

## 2. 폴더 및 노트북 계획

### outputs 폴더

`outputs/` 폴더는 MySQL Workbench에서 export한 SQL 분석 결과 CSV를 저장하는 위치로 사용한다.

### notebook 파일

노트북 파일명은 다음으로 계획한다.

`notebooks/01_user_journey_conversion_analysis.ipynb`

이 노트북은 SQL 분석 결과 CSV를 불러와 주요 지표와 패턴을 시각화하는 역할을 가진다.

## 3. CSV Export 대상

### 3.1 퍼널 분석 결과

| SQL 파일 | SQL 결과 | CSV 파일명 | 연결 분석 질문 |
|---|---|---|---|
| `sql/funnel_analysis.sql` | 퍼널 단계별 도달 세션 수 및 전환율 | `outputs/funnel_stage_conversion.csv` | 사용자는 구매 과정에서 어디서 가장 많이 이탈하는가? |
| `sql/funnel_analysis.sql` | 이탈 단계별 세션 수 | `outputs/funnel_drop_off_summary.csv` | 사용자는 구매 과정에서 어디서 가장 많이 이탈하는가? |

저장할 주요 컬럼 예시:

- `funnel_stage`
- `reached_session_count`
- `session_start_reach_rate`
- `previous_stage_conversion_rate`
- `drop_off_stage`
- `session_count`

### 3.2 구매 전환 관련 행동 분석 결과

| SQL 파일 | SQL 결과 | CSV 파일명 | 연결 분석 질문 |
|---|---|---|---|
| `sql/conversion_analysis.sql` | 구매 여부별 평균 행동량 비교 | `outputs/conversion_behavior_by_purchase_status.csv` | 어떤 행동이 구매 전환과 관련이 있는가? |
| `sql/conversion_analysis.sql` | 주요 이벤트 도달 여부별 구매 전환율 | `outputs/conversion_rate_by_event_reach.csv` | 어떤 행동이 구매 전환과 관련이 있는가? |
| `sql/conversion_analysis.sql` | 상품 상세 조회 수 구간별 구매 전환율 | `outputs/conversion_rate_by_view_item_segment.csv` | 어떤 행동이 구매 전환과 관련이 있는가? |
| `sql/conversion_analysis.sql` | 장바구니 추가 수 구간별 구매 전환율 | `outputs/conversion_rate_by_add_to_cart_segment.csv` | 어떤 행동이 구매 전환과 관련이 있는가? |

저장할 주요 컬럼 예시:

- `purchase_status`
- `session_count`
- `avg_total_event_count`
- `avg_view_item_count`
- `avg_add_to_cart_count`
- `begin_checkout_rate`
- `search_rate`
- `event_name`
- `reached_event_flag`
- `purchase_conversion_rate`
- `view_item_count_segment`
- `add_to_cart_count_segment`

### 3.3 구매 이후 행동 분석 결과

| SQL 파일 | SQL 결과 | CSV 파일명 | 연결 분석 질문 |
|---|---|---|---|
| `sql/post_purchase_analysis.sql` | 구매 후 리뷰 작성률 | `outputs/post_purchase_review_rate.csv` | 구매 이후 사용자는 어떤 행동을 하는가? |
| `sql/post_purchase_analysis.sql` | 구매 후 리뷰 작성까지 걸린 시간 | `outputs/post_purchase_minutes_to_review.csv` | 구매 이후 사용자는 어떤 행동을 하는가? |
| `sql/post_purchase_analysis.sql` | 같은 세션 리뷰 vs 별도 세션 리뷰 분류 | `outputs/post_purchase_review_session_detail.csv` | 구매 이후 사용자는 어떤 행동을 하는가? |
| `sql/post_purchase_analysis.sql` | 리뷰 세션 유형별 비중 | `outputs/post_purchase_review_session_type_share.csv` | 구매 이후 사용자는 어떤 행동을 하는가? |
| `sql/post_purchase_analysis.sql` | 상품별 리뷰 수와 평균 평점 | `outputs/post_purchase_product_review_summary.csv` | 구매 이후 사용자는 어떤 행동을 하는가? |

저장할 주요 컬럼 예시:

- `total_order_count`
- `reviewed_order_count`
- `review_rate`
- `review_id`
- `order_id`
- `minutes_to_review`
- `review_session_type`
- `review_count`
- `review_type_rate`
- `product_id`
- `product_name`
- `avg_rating`

## 4. Notebook 시각화 계획

### 4.1 퍼널 분석 시각화

1. 퍼널 단계별 도달 세션 수 bar chart
   - 데이터: `outputs/funnel_stage_conversion.csv`
   - 목적: 각 퍼널 단계에 도달한 세션 수를 비교한다.

2. 직전 단계 대비 전환율 line chart 또는 bar chart
   - 데이터: `outputs/funnel_stage_conversion.csv`
   - 목적: 어느 단계에서 전환율이 낮아지는지 확인한다.

3. 이탈 단계별 세션 수 bar chart
   - 데이터: `outputs/funnel_drop_off_summary.csv`
   - 목적: 가장 큰 이탈 단계가 어디인지 시각적으로 확인한다.

### 4.2 구매 전환 관련 행동 시각화

4. 구매/미구매 세션 평균 행동량 grouped bar chart
   - 데이터: `outputs/conversion_behavior_by_purchase_status.csv`
   - 목적: 구매 세션과 미구매 세션의 평균 이벤트 수, 상품 조회 수, 장바구니 추가 수를 비교한다.

5. 주요 이벤트 도달 여부별 구매 전환율 grouped bar chart
   - 데이터: `outputs/conversion_rate_by_event_reach.csv`
   - 목적: 특정 이벤트 도달 여부에 따라 구매 전환율이 어떻게 달라지는지 확인한다.

6. 상품 상세 조회 수 구간별 구매 전환율 bar chart
   - 데이터: `outputs/conversion_rate_by_view_item_segment.csv`
   - 목적: 상품 상세 조회 수가 많을수록 전환율이 높아지는지 확인한다.

7. 장바구니 추가 수 구간별 구매 전환율 bar chart
   - 데이터: `outputs/conversion_rate_by_add_to_cart_segment.csv`
   - 목적: 장바구니 추가 수 구간별 전환율 차이를 확인한다.

### 4.3 구매 이후 행동 시각화

8. 리뷰 작성 주문 비율 donut chart 또는 stacked bar
   - 데이터: `outputs/post_purchase_review_rate.csv`
   - 목적: 전체 주문 중 리뷰 작성 주문의 비율을 보여준다.

9. 리뷰 작성까지 걸린 시간 histogram
   - 데이터: `outputs/post_purchase_minutes_to_review.csv`
   - 목적: 즉시 리뷰와 지연 리뷰의 분포를 확인한다.

10. 리뷰 세션 유형별 비중 bar chart 또는 pie chart
    - 데이터: `outputs/post_purchase_review_session_type_share.csv`
    - 목적: 같은 구매 세션 리뷰와 별도 구매 이후 세션 리뷰의 비중을 비교한다.

11. 상품별 리뷰 수 bar chart
    - 데이터: `outputs/post_purchase_product_review_summary.csv`
    - 목적: 리뷰가 발생한 상품과 리뷰가 없는 상품을 비교한다.

12. 상품별 평균 평점 bar chart
    - 데이터: `outputs/post_purchase_product_review_summary.csv`
    - 목적: 리뷰가 있는 상품의 평균 평점을 비교한다.

## 5. 권장 작업 순서

1. `outputs/` 폴더를 생성한다.
2. MySQL Workbench에서 각 SQL 분석 결과를 CSV로 export한다.
3. CSV 파일명을 이 문서의 제안명과 맞춘다.
4. `notebooks/01_user_journey_conversion_analysis.ipynb`를 생성한다.
5. CSV 로딩 및 컬럼 확인 코드를 작성한다.
6. 분석 질문별 시각화를 작성한다.
7. 주요 그래프와 해석을 `docs/analysis_results.md` 또는 README 요약에 반영한다.

## 6. 해석상 주의

시각화 대상 데이터는 synthetic data 기반 SQL 분석 결과다. 따라서 그래프에서 보이는 패턴은 실제 서비스 인사이트가 아니라, SQL 분석 흐름과 시각화 흐름이 정상적으로 작동하는지 확인하기 위한 결과로 해석한다.
