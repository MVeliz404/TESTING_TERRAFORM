# =============================================================================
# iam.tf — context-root
# SA para poc-firestore-listener + bindings mínimos necesarios
# =============================================================================

resource "google_service_account" "root_functions_sa" {
  account_id   = "poc-root-sa"
  display_name = "PoC Root Context Service Account"
  project      = var.project_id
}

# Lee el documento del evento Firestore
resource "google_project_iam_member" "root_sa_datastore_viewer" {
  project = var.project_id
  role    = "roles/datastore.viewer"
  member  = "serviceAccount:${google_service_account.root_functions_sa.email}"
}

# Publica en el topic poc-test-topic (propiedad de context-process)
resource "google_project_iam_member" "root_sa_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.root_functions_sa.email}"
}

# Recibe eventos de Eventarc (trigger Firestore)
resource "google_project_iam_member" "root_sa_eventarc_receiver" {
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.root_functions_sa.email}"
}
