# =============================================================================
# iam.tf — context-process
# SA para poc-pubsub-handler y poc-task-handler + bindings mínimos
# =============================================================================

resource "google_service_account" "process_functions_sa" {
  account_id   = "poc-process-sa"
  display_name = "PoC Process Context Service Account"
  project      = var.project_id
}

# Recibe eventos de Eventarc (trigger Pub/Sub)
resource "google_project_iam_member" "process_sa_eventarc_receiver" {
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.process_functions_sa.email}"
}

# poc-pubsub-handler encola tareas en Cloud Tasks
resource "google_project_iam_member" "process_sa_tasks_enqueuer" {
  project = var.project_id
  role    = "roles/cloudtasks.enqueuer"
  member  = "serviceAccount:${google_service_account.process_functions_sa.email}"
}

# Cloud Tasks invoca poc-task-handler vía OIDC — necesita run.invoker
resource "google_project_iam_member" "process_sa_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.process_functions_sa.email}"
}

# poc-pubsub-handler crea tareas con OIDC usando esta misma SA.
# Para especificar una SA en el token OIDC de Cloud Tasks, el llamador
# necesita iam.serviceAccounts.actAs sobre esa SA (aunque sea la misma).
resource "google_service_account_iam_member" "process_sa_act_as_self" {
  service_account_id = google_service_account.process_functions_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.process_functions_sa.email}"
}
