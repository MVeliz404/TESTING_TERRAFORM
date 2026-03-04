# =============================================================================
# pubsub.tf — context-process
# Topic Pub/Sub que activa poc-pubsub-handler
#
# context-root publica en este topic por nombre (string plano en env var).
# context-process lo declara porque es quien tiene el trigger sobre él.
# =============================================================================

resource "google_pubsub_topic" "poc_test_topic" {
  name    = "poc-test-topic"
  project = var.project_id
}
