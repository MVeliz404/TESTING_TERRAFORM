# =============================================================================
# tasks.tf — context-process
# Cola Cloud Tasks que despacha peticiones a poc-task-handler
# =============================================================================

resource "google_cloud_tasks_queue" "poc_test_queue" {
  name     = "poc-test-queue"
  location = var.region
  project  = var.project_id

  rate_limits {
    max_dispatches_per_second = 5
    max_concurrent_dispatches = 3
  }

  retry_config {
    max_attempts = 3
  }
}
