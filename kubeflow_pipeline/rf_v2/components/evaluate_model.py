from kfp.dsl import component, Input, Output, Dataset, Model, Metrics


@component(
    base_image="pod-placement-trainer:v12"
)
def evaluate_model(
    model: Input[Model],
    x_train: Input[Dataset],
    y_train: Input[Dataset],
    x_test: Input[Dataset],
    y_test: Input[Dataset],
    scenario_test: Input[Dataset],
    metrics: Output[Metrics],
    metrics_csv: Output[Dataset],
):
    import joblib
    import pandas as pd
    from sklearn.metrics import mean_squared_error, mean_absolute_error

    def compute_top1_agreement(results_df):
        true_best = (
            results_df
            .groupby("scenario_id")["true_score"]
            .idxmin()
        )
        pred_best = (
            results_df
            .groupby("scenario_id")["predicted_score"]
            .idxmin()
        )

        true_best_rows = results_df.loc[true_best]
        pred_best_rows = results_df.loc[pred_best]

        matches = 0
        for scenario_id in true_best_rows["scenario_id"]:
            true_index = true_best_rows[
                true_best_rows["scenario_id"] == scenario_id
            ].index[0]
            pred_index = pred_best_rows[
                pred_best_rows["scenario_id"] == scenario_id
            ].index[0]
            if true_index == pred_index:
                matches += 1

        return matches / len(true_best_rows)

    def compute_test_metrics(y_true, y_pred, scenario_ids):
        rmse = mean_squared_error(y_true, y_pred) ** 0.5
        mae = mean_absolute_error(y_true, y_pred)

        results_df = pd.DataFrame({
            "scenario_id": scenario_ids,
            "true_score": y_true,
            "predicted_score": y_pred,
        })
        top1 = compute_top1_agreement(results_df)

        return rmse, mae, top1

    print("=" * 60)
    print("Loading model bundle")
    print("=" * 60)

    trained_models = joblib.load(model.path)

    print("=" * 60)
    print("Loading train and test datasets")
    print("=" * 60)

    X_train = pd.read_csv(x_train.path)
    y_train_true = pd.read_csv(y_train.path)["score"]

    X_test = pd.read_csv(x_test.path)
    y_test_df = pd.read_csv(y_test.path)
    scenario_df = pd.read_csv(scenario_test.path)

    y_true = y_test_df["score"]
    scenario_ids = scenario_df["scenario_id"]

    print(f"Training Samples : {len(X_train)}")
    print(f"Testing Samples  : {len(X_test)}")

    print("=" * 60)
    print("Generating Predictions and Calculating Metrics Per Model")
    print("=" * 60)

    rows = []

    for name, mdl in trained_models.items():

        train_preds = mdl.predict(X_train)
        test_preds = mdl.predict(X_test)

        train_rmse = mean_squared_error(y_train_true, train_preds) ** 0.5
        train_mae = mean_absolute_error(y_train_true, train_preds)

        test_rmse, test_mae, top1 = compute_test_metrics(
            y_true, test_preds, scenario_ids
        )

        rmse_gap = test_rmse - train_rmse
        mae_gap = test_mae - train_mae

        rows.append({
            "model": name,
            "train_rmse": train_rmse,
            "test_rmse": test_rmse,
            "rmse_gap": rmse_gap,
            "train_mae": train_mae,
            "test_mae": test_mae,
            "mae_gap": mae_gap,
            "top1_agreement": top1,
        })

        print(
            f"[{name}] "
            f"Train RMSE: {train_rmse:.4f} | Test RMSE: {test_rmse:.4f} | RMSE Gap: {rmse_gap:.4f} | "
            f"Train MAE: {train_mae:.4f} | Test MAE: {test_mae:.4f} | MAE Gap: {mae_gap:.4f} | "
            f"Top-1: {top1:.4f}"
        )

    metrics_df = pd.DataFrame(rows)

    print("=" * 60)
    print("Saving Metrics CSV")
    print("=" * 60)

    metrics_df.to_csv(metrics_csv.path, index=False)

    print(f"Metrics CSV saved at : {metrics_csv.path}")

    print("=" * 60)
    print("Logging Voting Regressor Metrics")
    print("=" * 60)

    voting_row = metrics_df[metrics_df["model"] == "voting_regressor"].iloc[0]
    metrics.log_metric("Test_RMSE", float(voting_row["test_rmse"]))
    metrics.log_metric("Test_MAE", float(voting_row["test_mae"]))
    metrics.log_metric("Top1_Agreement", float(voting_row["top1_agreement"]))
    metrics.log_metric("RMSE_Gap", float(voting_row["rmse_gap"]))
    metrics.log_metric("MAE_Gap", float(voting_row["mae_gap"]))

    print("=" * 60)
    print("Evaluation Completed")
    print("=" * 60)