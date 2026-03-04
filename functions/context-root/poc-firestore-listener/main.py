import json
import os
import functions_framework
from google.cloud import pubsub_v1
from google.events.cloud.firestore_v1.types import DocumentEventData


publisher = pubsub_v1.PublisherClient()


@functions_framework.cloud_event
def cloud_function(cloud_event):
    """
    Se activa cuando se crea o modifica un documento en poc_test_events/{docId}.
    1. Imprime el payload del evento Firestore.
    2. Publica un mensaje en poc-test-topic para encadenar con poc-pubsub-handler.
    """
    print("=" * 60)
    print("POC-FIRESTORE-LISTENER: Evento recibido de Firestore")
    print(f"Event ID  : {cloud_event['id']}")
    print(f"Event Type: {cloud_event['type']}")

    # Eventarc entrega el payload de Firestore como protobuf binario
    firestore_data = DocumentEventData.deserialize(cloud_event.data)

    # Convertir a dict serializable para logging
    fields = {}
    if firestore_data.value and firestore_data.value.fields:
        fields = {k: str(v) for k, v in firestore_data.value.fields.items()}
        print(f"Campos del documento: {json.dumps(fields, indent=2)}")
    else:
        print("El evento no contiene campos de documento (puede ser una eliminación).")

    # Publicar en Pub/Sub para activar poc-pubsub-handler
    project_id = os.environ.get("PROJECT_ID")
    topic_name = os.environ.get("TOPIC_NAME")

    if project_id and topic_name:
        topic_path = publisher.topic_path(project_id, topic_name)
        message_body = json.dumps({
            "source": "poc-firestore-listener",
            "event_id": cloud_event["id"],
            "document_fields": fields,
        }).encode("utf-8")

        future = publisher.publish(topic_path, message_body)
        print(f"Mensaje publicado en '{topic_name}'. Message ID: {future.result()}")
    else:
        print("WARNING: PROJECT_ID o TOPIC_NAME no configurados — no se publicó en Pub/Sub.")

    print("POC-FIRESTORE-LISTENER: Procesamiento completado")
    print("=" * 60)
