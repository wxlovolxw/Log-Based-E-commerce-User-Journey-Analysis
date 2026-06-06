# MySQL Execution Validation

## 목적

이 문서는 로컬 MySQL에서 `sql/schema.sql`과 `sql/seed_data.sql`을 순서대로 실행해 테이블 생성과 샘플 데이터 삽입이 정상 동작하는지 확인하는 방법을 정리한다.

`sql/basic_validation.sql`은 단순 실행 확인용이며, `sql/quality_checks.sql`은 정합성 검증용이다.

## 실행 순서

1. `sql/schema.sql`: 테이블 생성
2. `sql/seed_data.sql`: 샘플 데이터 삽입
3. `sql/basic_validation.sql`: 기본 실행 확인
4. `sql/quality_checks.sql`: 정합성 검증

## 로컬 MySQL 실행 예시

```bash
mysql -u <user> -p <database_name> < sql/schema.sql
mysql -u <user> -p <database_name> < sql/seed_data.sql
mysql -u <user> -p <database_name> < sql/basic_validation.sql
mysql -u <user> -p <database_name> < sql/quality_checks.sql
```

이미 같은 이름의 테이블이나 데이터가 존재하는 데이터베이스에서 실행하면 PK 중복 또는 테이블 중복 오류가 발생할 수 있다. 필요하면 테스트용 빈 데이터베이스를 만든 뒤 위 순서대로 실행한다.

## 기본 확인 항목

- 테이블별 row count 확인
- `event_logs` 최종 43건 확인
- 구매 이벤트와 주문/세션 조인 확인
- 리뷰 작성 이벤트와 리뷰 테이블 조인 확인

## 실행 검증 결과

MySQL Workbench에서 다음 순서로 SQL 파일을 실행했다.

1. `sql/schema.sql`
2. `sql/seed_data.sql`
3. `sql/basic_validation.sql`

실행 결과 테이블 생성과 샘플 데이터 삽입이 정상적으로 완료되었다.

`sql/basic_validation.sql`의 row count 확인 결과는 다음과 같다.

| table_name | row_count |
|---|---:|
| `users` | 5 |
| `categories` | 4 |
| `products` | 8 |
| `sessions` | 8 |
| `orders` | 3 |
| `order_items` | 6 |
| `reviews` | 3 |
| `event_logs` | 43 |

`event_logs`는 최종 43건으로 확인되었다.

여러 Result Grid가 생성되었으며, 구매 이벤트-주문 조인과 리뷰 이벤트-리뷰 조인 결과도 정상적으로 조회되었다.

## 정합성 검증 결과

MySQL Workbench에서 `sql/quality_checks.sql`을 실행했다.

총 18개 정합성 검증 쿼리를 실행했으며, 각 쿼리는 문제가 있는 행을 반환하는 방식으로 작성되어 있다. 정상 데이터라면 각 검증 쿼리의 결과는 0건이어야 한다.

실행 결과 모든 검증 쿼리에서 위반 행이 0건으로 확인되었다.

따라서 현재 `sql/seed_data.sql`의 샘플 데이터는 `docs/data_quality_rules.md`에 정의한 정합성 규칙을 만족하는 것으로 확인했다.

## 다음 단계

- SQL 분석 쿼리 작성

## Funnel Analysis Execution Result

MySQL Workbench에서 `sql/funnel_analysis.sql`을 실행했다.

총 6개 퍼널 분석 쿼리가 정상 실행되었다.

이탈 단계별 세션 수 결과는 다음과 같이 확인되었다.

| drop_off_stage | session_count |
|---|---:|
| `completed` | 3 |
| `search` | 1 |
| `view_item` | 1 |
| `add_to_cart` | 1 |
| `begin_checkout` | 1 |
| `post_purchase_activity` | 1 |

`post_purchase_activity`는 구매 이후 `review_write`만 발생한 세션이다. 따라서 구매 퍼널 이탈과 별도로 해석한다.

다음 단계는 분석 결과 해석 문서화 또는 추가 SQL 분석 쿼리 작성이다.
