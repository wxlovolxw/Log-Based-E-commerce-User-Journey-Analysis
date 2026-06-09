from pathlib import Path

import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler


PROJECT_ROOT = Path(__file__).resolve().parents[1]
INPUT_PATH = PROJECT_ROOT / "outputs" / "session_level_features.csv"
METRICS_PATH = PROJECT_ROOT / "outputs" / "model_logistic_regression_metrics.csv"
CONFUSION_MATRICES_PATH = (
    PROJECT_ROOT / "outputs" / "model_logistic_regression_confusion_matrices.csv"
)
COEFFICIENTS_WITH_CHECKOUT_PATH = (
    PROJECT_ROOT / "outputs" / "model_logistic_regression_coefficients_with_checkout.csv"
)
COEFFICIENTS_WITHOUT_CHECKOUT_PATH = (
    PROJECT_ROOT / "outputs" / "model_logistic_regression_coefficients_without_checkout.csv"
)

TARGET_COLUMN = "is_purchase"
BASE_EXCLUDE_COLUMNS = ["session_id", "user_id", TARGET_COLUMN]
CHECKOUT_COLUMNS = ["begin_checkout_count", "has_begin_checkout"]


def load_session_features() -> pd.DataFrame:
    """세션 단위 feature 데이터를 로드합니다."""
    if not INPUT_PATH.exists():
        raise FileNotFoundError(f"Input file not found: {INPUT_PATH}")

    return pd.read_csv(INPUT_PATH)


def validate_columns(df: pd.DataFrame) -> None:
    """모델링에 필요한 컬럼이 있는지 확인합니다."""
    required_columns = set(BASE_EXCLUDE_COLUMNS + CHECKOUT_COLUMNS)
    missing_columns = sorted(required_columns - set(df.columns))

    if missing_columns:
        raise ValueError(f"Missing required columns: {missing_columns}")


def build_feature_sets(df: pd.DataFrame) -> dict[str, list[str]]:
    """Model A/B에 사용할 feature 목록을 구성합니다."""
    with_checkout_features = [
        column for column in df.columns if column not in BASE_EXCLUDE_COLUMNS
    ]
    without_checkout_features = [
        column
        for column in with_checkout_features
        if column not in CHECKOUT_COLUMNS
    ]

    return {
        "with_checkout": with_checkout_features,
        "without_checkout": without_checkout_features,
    }


def build_model() -> Pipeline:
    """표준화와 Logistic Regression을 포함한 Pipeline을 생성합니다."""
    return Pipeline(
        steps=[
            ("scaler", StandardScaler()),
            (
                "logistic_regression",
                LogisticRegression(max_iter=1000, class_weight="balanced"),
            ),
        ]
    )


def evaluate_model(
    model_name: str,
    features: list[str],
    df: pd.DataFrame,
) -> tuple[dict[str, float | str | int], list[dict[str, int | str]], pd.DataFrame]:
    """단일 모델을 학습하고 평가 결과, confusion matrix, coefficient를 반환합니다."""
    X = df[features]
    y = df[TARGET_COLUMN]

    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=0.2,
        random_state=42,
        stratify=y,
    )

    model = build_model()
    model.fit(X_train, y_train)

    y_pred = model.predict(X_test)
    y_proba = model.predict_proba(X_test)[:, 1]

    metrics = {
        "model": model_name,
        "n_features": len(features),
        "accuracy": accuracy_score(y_test, y_pred),
        "precision": precision_score(y_test, y_pred, zero_division=0),
        "recall": recall_score(y_test, y_pred, zero_division=0),
        "f1": f1_score(y_test, y_pred, zero_division=0),
        "roc_auc": roc_auc_score(y_test, y_proba),
    }

    tn, fp, fn, tp = confusion_matrix(y_test, y_pred, labels=[0, 1]).ravel()
    confusion_rows = [
        {"model": model_name, "actual": 0, "predicted": 0, "count": int(tn)},
        {"model": model_name, "actual": 0, "predicted": 1, "count": int(fp)},
        {"model": model_name, "actual": 1, "predicted": 0, "count": int(fn)},
        {"model": model_name, "actual": 1, "predicted": 1, "count": int(tp)},
    ]

    coefficients = model.named_steps["logistic_regression"].coef_[0]
    coefficient_df = pd.DataFrame(
        {
            "model": model_name,
            "feature": features,
            "coefficient": coefficients,
            "abs_coefficient": abs(coefficients),
        }
    ).sort_values("abs_coefficient", ascending=False)

    return metrics, confusion_rows, coefficient_df


def print_model_summary(
    metrics_df: pd.DataFrame,
    confusion_matrices_df: pd.DataFrame,
) -> None:
    """실행 결과의 핵심 지표를 콘솔에 출력합니다."""
    print("\nLogistic Regression baseline results")
    print("=" * 44)

    for _, row in metrics_df.iterrows():
        print(
            f"\nModel: {row['model']}\n"
            f"- n_features: {int(row['n_features'])}\n"
            f"- accuracy: {row['accuracy']:.4f}\n"
            f"- precision: {row['precision']:.4f}\n"
            f"- recall: {row['recall']:.4f}\n"
            f"- f1: {row['f1']:.4f}\n"
            f"- roc_auc: {row['roc_auc']:.4f}"
        )

        model_confusion = confusion_matrices_df[
            confusion_matrices_df["model"] == row["model"]
        ]
        print("- confusion_matrix:")
        for _, cm_row in model_confusion.iterrows():
            print(
                "  "
                f"actual={int(cm_row['actual'])}, "
                f"predicted={int(cm_row['predicted'])}, "
                f"count={int(cm_row['count'])}"
            )


def main() -> None:
    """세션 행동 feature 기반 Logistic Regression baseline을 실행합니다."""
    df = load_session_features()
    validate_columns(df)

    feature_sets = build_feature_sets(df)
    metrics_rows = []
    confusion_rows = []
    coefficient_outputs = {}

    for model_name, features in feature_sets.items():
        metrics, model_confusion_rows, coefficient_df = evaluate_model(
            model_name=model_name,
            features=features,
            df=df,
        )
        metrics_rows.append(metrics)
        confusion_rows.extend(model_confusion_rows)
        coefficient_outputs[model_name] = coefficient_df

    metrics_df = pd.DataFrame(metrics_rows)
    confusion_matrices_df = pd.DataFrame(confusion_rows)

    METRICS_PATH.parent.mkdir(parents=True, exist_ok=True)
    metrics_df.to_csv(METRICS_PATH, index=False)
    confusion_matrices_df.to_csv(CONFUSION_MATRICES_PATH, index=False)
    coefficient_outputs["with_checkout"].to_csv(
        COEFFICIENTS_WITH_CHECKOUT_PATH,
        index=False,
    )
    coefficient_outputs["without_checkout"].to_csv(
        COEFFICIENTS_WITHOUT_CHECKOUT_PATH,
        index=False,
    )

    print_model_summary(metrics_df, confusion_matrices_df)
    print("\nSaved output files:")
    print(f"- {METRICS_PATH.relative_to(PROJECT_ROOT)}")
    print(f"- {CONFUSION_MATRICES_PATH.relative_to(PROJECT_ROOT)}")
    print(f"- {COEFFICIENTS_WITH_CHECKOUT_PATH.relative_to(PROJECT_ROOT)}")
    print(f"- {COEFFICIENTS_WITHOUT_CHECKOUT_PATH.relative_to(PROJECT_ROOT)}")


if __name__ == "__main__":
    main()
