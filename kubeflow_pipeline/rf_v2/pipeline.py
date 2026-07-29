from kfp import compiler
from kfp.dsl import pipeline

from components.load_dataset import load_dataset
from components.preprocess import preprocess
from components.train_model import train_model
from components.evaluate_model import evaluate_model
from components.upload_model import upload_model
from components.upload_metrics import upload_metrics


@pipeline(
    name="pod-placement-training-pipeline",
    description="Voting Regressor Training Pipeline (RF, XGBoost, CatBoost, GBR, ExtraTrees)"
)
def training_pipeline():

    load_task = load_dataset()
    load_task.set_caching_options(False)

    preprocess_task = preprocess(
        dataset=load_task.outputs["dataset"]
    )
    preprocess_task.set_caching_options(False)

    train_task = train_model(
        x_train=preprocess_task.outputs["x_train"],
        y_train=preprocess_task.outputs["y_train"]
    )
    train_task.set_caching_options(False)

    evaluate_task = evaluate_model(
        model=train_task.outputs["model"],
        x_train=preprocess_task.outputs["x_train"],
        y_train=preprocess_task.outputs["y_train"],
        x_test=preprocess_task.outputs["x_test"],
        y_test=preprocess_task.outputs["y_test"],
        scenario_test=preprocess_task.outputs["scenario_test"]
    )
    evaluate_task.set_caching_options(False)

    upload_model_task = upload_model(
        model=train_task.outputs["model"]
    )
    upload_model_task.set_caching_options(False)
    upload_model_task.after(evaluate_task)

    upload_metrics_task = upload_metrics(
        metrics_csv=evaluate_task.outputs["metrics_csv"]
    )
    upload_metrics_task.set_caching_options(False)


if __name__ == "__main__":
    compiler.Compiler().compile(
        pipeline_func=training_pipeline,
        package_path="pipeline.yaml"
    )

    print("Pipeline compiled successfully.")