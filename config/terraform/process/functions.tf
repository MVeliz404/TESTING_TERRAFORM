# =============================================================================
# functions.tf — context-process
# Cloud Functions del contexto process
#
# Función 1: poc-pubsub-handler
#   Trigger : Eventarc — Pub/Sub messagePublished en poc-test-topic
#   Acción  : Log del mensaje + crea tarea en poc-tasks-queue → poc-task-handler
#
# Función 2: poc-task-handler
#   Trigger : HTTP — invocada por Cloud Tasks vía OIDC
#   Acción  : Log del payload, retorna 200 OK
#
# Dependencia interna: poc_pubsub_handler referencia la URI de poc_task_handler
# Terraform crea poc_task_handler primero para resolver la referencia.
# =============================================================================

# =============================================================================
# FUNCIÓN 1: poc-pubsub-handler
# =============================================================================
resource "google_cloudfunctions2_function" "poc_pubsub_handler" {
  name     = "poc-pubsub-handler"
  location = var.region
  project  = var.project_id

  # Espera a que los IAM bindings propaguen antes de crear el trigger Eventarc.
  depends_on = [
    google_project_iam_member.process_sa_eventarc_receiver,
    google_project_iam_member.process_sa_tasks_enqueuer,
    google_project_iam_member.process_sa_run_invoker,
    google_service_account_iam_member.process_sa_act_as_self,
  ]

  build_config {
    runtime     = "python312"
    entry_point = "cloud_function"
    source {
      storage_source {
        bucket = google_storage_bucket.process_source_code.name
        object = google_storage_bucket_object.poc_pubsub_handler.name
      }
    }
  }

  service_config {
    max_instance_count    = 5
    available_memory      = "256M"
    timeout_seconds       = 60
    service_account_email = google_service_account.process_functions_sa.email
    ingress_settings      = "ALLOW_INTERNAL_ONLY"

    environment_variables = {
      PROJECT_ID      = var.project_id
      REGION          = var.region
      QUEUE_NAME      = google_cloud_tasks_queue.poc_test_queue.name
      SERVICE_ACCOUNT = google_service_account.process_functions_sa.email
      # Referencia intra-contexto: ambas funciones están en process
      TASK_HANDLER_URL = google_cloudfunctions2_function.poc_task_handler.service_config[0].uri
    }
  }

  event_trigger {
    trigger_region        = var.region
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = google_pubsub_topic.poc_test_topic.id
    service_account_email = google_service_account.process_functions_sa.email
    retry_policy          = "RETRY_POLICY_RETRY"
  }
}

# =============================================================================
# FUNCIÓN 2: poc-task-handler
# =============================================================================
resource "google_cloudfunctions2_function" "poc_task_handler" {
  name     = "poc-task-handler"
  location = var.region
  project  = var.project_id

  depends_on = [
    google_project_iam_member.process_sa_run_invoker,
  ]

  build_config {
    runtime     = "python312"
    entry_point = "cloud_function"
    source {
      storage_source {
        bucket = google_storage_bucket.process_source_code.name
        object = google_storage_bucket_object.poc_task_handler.name
      }
    }
  }

  service_config {
    max_instance_count    = 5
    available_memory      = "256M"
    timeout_seconds       = 60
    service_account_email = google_service_account.process_functions_sa.email
    ingress_settings      = "ALLOW_INTERNAL_ONLY"
  }
}
