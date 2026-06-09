# Log-Based-E-commerce-User-Journey-Analysis

로그 기반 이커머스 유저 여정 분석 프로젝트

## 프로젝트 개요

이 프로젝트는 이커머스 사용자 행동 로그를 직접 설계하고, synthetic data를 MySQL에 적재한 뒤 정합성 검증, SQL 분석, Python 기반 세션 단위 분석 및 구매 전환 모델링, Tableau 대시보드 설계까지 연결하는 end-to-end 분석 프로젝트입니다.

기존에 완료한 DB 설계, synthetic data 생성 및 적재, SQL 기반 퍼널/전환/리뷰 행동 분석 결과는 유지합니다. 프로젝트의 최종 포지션은 SQL에서 원천 로그 기반 핵심 지표를 정확히 산출하고, Python 기반 구매 전환 예측 및 실험 설계로 확장한 뒤, Tableau 대시보드로 전달 가능한 형태로 최종 분석 결과와 인사이트를 정리하는 흐름입니다.

## 프로젝트 목표

- 로그 기반 이커머스 유저 여정을 이벤트 단위로 설계한다.
- MySQL 기반 데이터 모델과 정합성 검증 규칙을 구성한다.
- SQL로 퍼널, 구매 전환, 구매 이후 리뷰 행동 관련 핵심 지표를 산출한다.
- Python 기반 세션 단위 분석 및 구매 전환 모델링을 수행한다.
- 분석 결과를 바탕으로 A/B 테스트 설계안을 도출한다.
- Tableau 대시보드로 전달 가능한 형태로 최종 분석 결과와 인사이트를 정리한다.
- SQL, Python, Tableau를 연결한 end-to-end 분석 흐름을 검증한다.

## 기술 스택

- SQL: MySQL
- Data Modeling: Entity-Relationship Design, PK/FK, Data Quality Rules
- Data Generation: Python
- Analysis: SQL, Python
- Visualization: Python, Tableau
- Documentation: Markdown
- Tools: MySQL Workbench, VSCode, Git/GitHub

## 핵심 분석 질문

- 사용자는 구매 퍼널의 어느 단계에서 가장 많이 이탈하는가?
- 어떤 세션 단위 행동 특성이 구매 전환과 관련이 있는가?
- 구매 전환 여부를 예측하기 위해 어떤 행동 지표를 feature로 구성할 수 있는가?
- 구매 이후 리뷰 작성 행동은 어떤 패턴으로 나타나는가?
- 퍼널 및 전환 분석 결과를 바탕으로 어떤 A/B 테스트 설계안을 도출할 수 있는가?

## 전체 분석 흐름

1. 요구사항 분석
2. 이벤트 로그 구조 및 주요 엔티티 정의
3. MySQL 테이블 설계 및 `schema.sql` 작성
4. seed data 및 synthetic data 생성
5. synthetic data MySQL 적재
6. 데이터 정합성 검증 SQL 작성 및 실행
7. SQL 기반 퍼널, 구매 전환, 리뷰 행동 분석
8. Python 기반 세션 단위 분석 및 구매 전환 모델링
9. Python 기반 구매 전환 예측 및 실험 설계
10. 분석 결과 기반 A/B 테스트 설계안 도출
11. Tableau 대시보드로 전달 가능한 형태의 최종 분석 결과 및 인사이트 정리

## SQL / Python / Tableau 역할 구분

| 도구 | 역할 |
|---|---|
| SQL | 원천 로그와 관계형 테이블에서 퍼널, 전환, 리뷰 행동 관련 핵심 지표를 정확하게 산출 |
| Python | SQL 분석 결과를 세션 단위 데이터셋으로 확장하고, 구매 전환 예측 및 실험 설계에 활용 |
| Tableau | 최종 대시보드로 시각화 가능한 주요 지표, 분석 결과, 인사이트를 정리 |

## 중점적으로 설계한 부분

- 비즈니스 질문에서 출발해 이벤트 로그와 엔티티를 설계했다.
- `event_logs`와 주요 엔티티 테이블을 분리해 분석과 정합성 검증이 가능하도록 구성했다.
- 데이터 정합성 규칙을 문서화하고 SQL로 검증했다.
- 퍼널 이탈, 구매 전환 관련 행동, 구매 이후 리뷰 행동을 분석하는 SQL을 작성했다.
- synthetic data 기반 분석 결과의 한계를 문서에 명확히 남겼다.
- SQL 분석 결과를 Python 기반 세션 단위 분석 및 구매 전환 모델링과 Tableau 대시보드 설계로 연결하는 최종 포지션을 정의했다.

## 데이터 설계 요약

이벤트 로그 설계는 GA4-style event-based analytics 개념을 참고했으며, 스키마와 데이터셋은 이 프로젝트 목적에 맞게 직접 설계했습니다.

주요 이벤트:

- `session_start`
- `search`
- `view_item_list`
- `view_item`
- `add_to_cart`
- `begin_checkout`
- `purchase`
- `review_write`

주요 테이블:

- `users`
- `sessions`
- `event_logs`
- `categories`
- `products`
- `orders`
- `order_items`
- `reviews`

## 주요 SQL 파일

- [`sql/schema.sql`](sql/schema.sql): MySQL 테이블 생성
- [`sql/seed_data.sql`](sql/seed_data.sql): 소규모 검증용 샘플 데이터
- [`sql/seed_synthetic_data.sql`](sql/seed_synthetic_data.sql): 분석 확장용 synthetic data
- [`sql/basic_validation.sql`](sql/basic_validation.sql): 기본 실행 확인
- [`sql/quality_checks.sql`](sql/quality_checks.sql): 데이터 정합성 검증
- [`sql/funnel_analysis.sql`](sql/funnel_analysis.sql): 퍼널 및 이탈 분석
- [`sql/conversion_analysis.sql`](sql/conversion_analysis.sql): 구매 전환 관련 행동 분석
- [`sql/post_purchase_analysis.sql`](sql/post_purchase_analysis.sql): 구매 이후 리뷰 행동 분석
- [`sql/session_level_features.sql`](sql/session_level_features.sql): 세션 단위 구매 전환 모델링 feature dataset 생성

## 주요 Python 파일

- [`scripts/generate_synthetic_data.py`](scripts/generate_synthetic_data.py): synthetic data 생성
- [`scripts/model_logistic_regression.py`](scripts/model_logistic_regression.py): 세션 단위 구매 전환 예측 Logistic Regression baseline 모델링
- [`notebooks/01_user_journey_conversion_analysis.ipynb`](notebooks/01_user_journey_conversion_analysis.ipynb): SQL/Python 분석 결과 확인 및 저장된 모델링 결과 요약

## Synthetic Data 규모

| Table | Row Count |
|---|---:|
| `users` | 300 |
| `categories` | 4 |
| `products` | 30 |
| `sessions` | 1000 |
| `orders` | 282 |
| `order_items` | 558 |
| `reviews` | 112 |
| `event_logs` | 5832 |

## 주요 SQL 분석 결과

아래 결과는 실제 서비스 데이터가 아닌 synthetic data를 기준으로 한 분석 결과이며, SQL 분석 흐름과 지표 산출 방식 검증을 목적으로 해석합니다.

- synthetic data 기준 전체 1,000개 세션 중 282개 세션이 `purchase`까지 도달했다.
- 가장 큰 이탈은 `view_item` 단계에서 발생했다.
- 구매 세션은 미구매 세션보다 평균 이벤트 수, 상품 상세 조회 수, 장바구니 추가 수가 높게 나타났다.
- `begin_checkout`에 도달한 세션의 구매 전환율은 77.05%로 확인했다.
- 전체 주문 282건 중 112건이 리뷰 작성으로 이어졌고, 주문 기준 리뷰 작성률은 39.72%였다.
- 리뷰 중 66.07%는 같은 구매 세션에서 작성되었고, 33.93%는 별도 구매 이후 세션에서 작성되었다.

## Python 모델링 결과

`outputs/session_level_features.csv`를 기반으로 세션 단위 구매 전환 예측 모델링을 수행했다. 모델 학습과 평가는 [`scripts/model_logistic_regression.py`](scripts/model_logistic_regression.py)에 분리했고, [`notebooks/01_user_journey_conversion_analysis.ipynb`](notebooks/01_user_journey_conversion_analysis.ipynb)에서는 저장된 모델링 결과 CSV를 불러와 요약 및 해석했다.

Logistic Regression baseline은 두 가지 feature 구성으로 비교했다.

| 모델 | feature 구성 | F1 | ROC-AUC |
|---|---|---:|---:|
| `with_checkout` | `begin_checkout_count`, `has_begin_checkout` 포함 | 0.9032 | 0.9838 |
| `without_checkout` | 구매 직전 행동인 `begin_checkout_count`, `has_begin_checkout` 제외 | 0.8889 | 0.9834 |

`begin_checkout` 관련 변수를 제외해도 성능이 크게 유지되어, 결제 이전 세션 행동 패턴만으로도 구매 전환 여부를 일정 수준 이상 구분할 수 있음을 확인했다. 다만 본 데이터는 synthetic data이므로 이 성능을 실제 서비스 예측 성능으로 일반화하지 않는다.

`without_checkout` 모델 기준으로는 `event_count`와 `has_add_to_cart`가 주요 양의 신호로 나타났다. 일부 세부 행동 횟수 변수는 음의 계수를 보였으나, 이는 `event_count`, `has_add_to_cart` 등과 정보가 중복되면서 계수 부호가 분산된 결과로 해석했다. 따라서 개별 coefficient의 부호를 단독으로 해석하기보다, 전체 행동량과 장바구니 도달 여부가 구매 전환을 구분하는 핵심 신호라는 점에 초점을 두었다.

초기 모델링 과정에서 `session_duration_minutes`가 `purchase`, `review_write` 이벤트를 포함할 수 있는 target leakage 가능성을 확인했다. 이후 `sql/session_level_features.sql`에서 `session_duration_minutes`를 `purchase`, `review_write` 제외 기준으로 재정의했다. 수정 후에도 모델 성능이 유지되어, 보수적으로 feature 정의를 조정한 뒤에도 모델링 흐름이 안정적으로 작동함을 확인했다.

## 해석상 주의

현재 데이터는 실제 서비스 데이터가 아니라 synthetic data입니다. 따라서 위 분석 결과를 실제 서비스의 전환율, 이탈 지점, 리뷰 작성률로 일반화하지 않습니다.

이 프로젝트의 목적은 이벤트 로그 설계, 데이터 모델링, 정합성 검증, SQL 기반 지표 산출, Python 기반 세션 단위 feature 설계와 구매 전환 예측 분석 파이프라인, Tableau 대시보드 설계로 이어지는 분석 흐름을 검증하는 것입니다. 모델링 결과 역시 실제 운영 모델 구축이 아니라, 세션 단위 feature 설계와 모델링 파이프라인 검증 결과로 해석합니다.

A/B 테스트 역시 실제 실험을 수행한 것이 아니라, synthetic data 기반 분석 흐름에서 확인한 퍼널 및 전환 지표를 바탕으로 향후 검증 가능한 A/B 테스트 설계안을 도출하는 단계로 정의합니다.

## 문서 목록

- [`docs/project_plan.md`](docs/project_plan.md)
- [`docs/event_definition.md`](docs/event_definition.md)
- [`docs/entity_definition.md`](docs/entity_definition.md)
- [`docs/table_specification.md`](docs/table_specification.md)
- [`docs/data_quality_rules.md`](docs/data_quality_rules.md)
- [`docs/mysql_execution_validation.md`](docs/mysql_execution_validation.md)
- [`docs/analysis_results.md`](docs/analysis_results.md)
- [`docs/ab_test_design.md`](docs/ab_test_design.md)
- [`docs/tableau_dashboard_design.md`](docs/tableau_dashboard_design.md)
- [`docs/decision_log.md`](docs/decision_log.md)

## 실행 방법

MySQL Workbench 기준 실행 예시는 다음과 같습니다.

```sql
DROP DATABASE IF EXISTS ecommerce_journey;
CREATE DATABASE ecommerce_journey;
USE ecommerce_journey;
```

SQL 파일 실행 순서:

1. `sql/schema.sql`
2. `sql/seed_synthetic_data.sql`
3. `sql/basic_validation.sql`
4. `sql/quality_checks.sql`
5. `sql/funnel_analysis.sql`
6. `sql/conversion_analysis.sql`
7. `sql/post_purchase_analysis.sql`
8. `sql/session_level_features.sql`

Python 모델링 실행:

```bash
python scripts/model_logistic_regression.py
```

## 다음 단계

- 실제 Tableau 구현 또는 최종 포트폴리오 정리

분석 결과 기반 A/B 테스트 설계안은 [`docs/ab_test_design.md`](docs/ab_test_design.md)에 1차 정리했습니다. Tableau 대시보드 설계안은 [`docs/tableau_dashboard_design.md`](docs/tableau_dashboard_design.md)에 1차 정리했습니다.
