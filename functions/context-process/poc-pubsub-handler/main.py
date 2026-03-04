import json
import base64
import os
import datetime
import functions_framework
from google.cloud import tasks_v2
from google.protobuf import timestamp_pb2


@functions_framework.cloud_event
def cloud_function(cloud_event):
    """
    Se activa con cada mensaje publicado en poc-test-topic.
    1. Decodifica el mensaje Pub/Sub.
    2. Crea una tarea en poc-test-queue apuntando a poc-task-handler.
    """
    print("=" * 60)
    print("POC-PUBSUB-HANDLER: Mensaje recibido de Pub/Sub")
    print(f"Event ID  : {cloud_event['id']}")
    print(f"Event Type: {cloud_event['type']}")

    # El payload de Eventarc Pub/Sub tiene el mensaje en cloud_event.data["message"]
    pubsub_message = cloud_event.data.get("message", {})

    if "data" in pubsub_message:
        decoded = base64.b64decode(pubsub_message["data"]).decode("utf-8")
        print(f"Mensaje decodificado: {decoded}")
        try:
            message_payload = json.loads(decoded)
        except json.JSONDecodeError:
            message_payload = {"raw": decoded}
    else:
        print("El mensaje Pub/Sub no contenía campo 'data'.")
        message_payload = {}

    print(f"Attributes: {pubsub_message.get('attributes', {})}")

    # Variables de entorno inyectadas por Terraform
    project_id       = os.environ.get("PROJECT_ID")
    region           = os.environ.get("REGION", "us-central1")
    queue_name       = os.environ.get("QUEUE_NAME")
    task_handler_url = os.environ.get("TASK_HANDLER_URL")
    service_account  = os.environ.get("SERVICE_ACCOUNT")

    print(f"Configuración: project={project_id}, queue={queue_name}, url={task_handler_url}")

    if all([project_id, queue_name, task_handler_url, service_account]):
        client = tasks_v2.CloudTasksClient()
        parent = client.queue_path(project_id, region, queue_name)

        task_body = json.dumps({
            "source": "poc-pubsub-handler",
            "original_message": message_payload,
            "event_id": cloud_event["id"],
        }).encode("utf-8")

        # Tiempo de schedule: ahora + 5 segundos (evita race conditions)
        schedule_time = datetime.datetime.utcnow() + datetime.timedelta(seconds=5)
        timestamp = timestamp_pb2.Timestamp()
        timestamp.FromDatetime(schedule_time)

        task = {
            "http_request": {
                "http_method": tasks_v2.HttpMethod.POST,
                "url": task_handler_url,
                "headers": {"Content-Type": "application/json"},
                "body": task_body,
                "oidc_token": {
                    "service_account_email": service_account,
                    "audience": task_handler_url,
                },
            },
            "schedule_time": timestamp,
        }

        response = client.create_task(request={"parent": parent, "task": task})
        print(f"Tarea creada exitosamente: {response.name}")
    else:
        missing = [k for k, v in {
            "PROJECT_ID": project_id, "QUEUE_NAME": queue_name,
            "TASK_HANDLER_URL": task_handler_url, "SERVICE_ACCOUNT": service_account
        }.items() if not v]
        print(f"WARNING: Variables de entorno faltantes: {missing} — no se creó la tarea.")

    print("POC-PUBSUB-HANDLER: Procesamiento completado")
    print("=" * 60)
