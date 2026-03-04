# =============================================================================
# functions.tf — context-root
# Cloud Functions del contexto root
#
# Función: poc-firestore-listener
#   Trigger : Eventarc — Firestore document.v1.written
#   Colección: poc_test_events/{docId}
#   Acción  : Log del doc + publica en poc-test-topic (propiedad de context-process)
#
# NOTA: TOPIC_NAME es un string plano (var.output_topic_name).
# No hay referencia Terraform a context-process — el acoplamiento es solo en runtime.
# =============================================================================

resource "google_cloudfunctions2_function" "poc_firestore_listener" {
  name     = "poc-firestore-listener"
  location = var.region
  project  = var.project_id

  # Espera a que los IAM bindings propaguen antes de crear el trigger Eventarc.
  # Sin esto, GCP puede rechazar la creación con 403 por race condition.
  depends_on = [
    google_project_iam_member.root_sa_eventarc_receiver,
    google_project_iam_member.root_sa_datastore_viewer,
    google_project_iam_member.root_sa_pubsub_publisher,
    google_project_iam_member.root_sa_run_invoker,
  ]

  build_config {
    runtime     = "python312"
    entry_point = "cloud_function"
    source {
      storage_source {
        bucket = google_storage_bucket.root_source_code.name
        object = google_storage_bucket_object.poc_firestore_listener.name
      }
    }
  }

  service_config {
    max_instance_count    = 5
    available_memory      = "256M"
    timeout_seconds       = 60
    service_account_email = google_service_account.root_functions_sa.email
    ingress_settings      = "ALLOW_INTERNAL_ONLY"

    environment_variables = {
      PROJECT_ID = var.project_id
      # String plano — no referencia ningún recurso de context-process
      TOPIC_NAME = var.output_topic_name
    }
  }

  event_trigger {
    # NOTA: trigger_region debe coincidir con la región de la Firestore database,
    # no con var.region (región de la función). Consultar: gcloud firestore databases list
    trigger_region        = var.firestore_location
    event_type            = "google.cloud.firestore.document.v1.written"
    service_account_email = google_service_account.root_functions_sa.email
    retry_policy          = "RETRY_POLICY_DO_NOT_RETRY"

    event_filters {
      attribute = "database"
      value     = "(default)"
    }

    event_filters {
      attribute = "document"
      value     = "poc_test_events/{docId}"
      operator  = "match-path-pattern"
    }
  }
}
