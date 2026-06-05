# MySQL Execution Validation

## 목적

이 문서는 로컬 MySQL에서 `sql/schema.sql`과 `sql/seed_data.sql`을 순서대로 실행해 테이블 생성과 샘플 데이터 삽입이 정상 동작하는지 확인하는 방법을 정리한다.

전체 정합성 검증 규칙은 이후 `quality_checks.sql`에서 별도로 다룬다. 이 문서와 `sql/basic_validation.sql`은 단순 실행 확인용이다.

## 실행 순서

1. `sql/schema.sql`: 테이블 생성
2. `sql/seed_data.sql`: 샘플 데이터 삽입
3. `sql/basic_validation.sql`: 기본 실행 확인

## 로컬 MySQL 실행 예시

```bash
mysql -u <user> -p <database_name> < sql/schema.sql
mysql -u <user> -p <database_name> < sql/seed_data.sql
mysql -u <user> -p <database_name> < sql/basic_validation.sql
```

이미 같은 이름의 테이블이나 데이터가 존재하는 데이터베이스에서 실행하면 PK 중복 또는 테이블 중복 오류가 발생할 수 있다. 필요하면 테스트용 빈 데이터베이스를 만든 뒤 위 순서대로 실행한다.

## 기본 확인 항목

- 테이블별 row count 확인
- `event_logs` 최종 43건 확인
- 구매 이벤트와 주문/세션 조인 확인
- 리뷰 작성 이벤트와 리뷰 테이블 조인 확인
