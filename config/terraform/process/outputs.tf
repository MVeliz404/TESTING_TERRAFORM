# =============================================================================
# outputs.tf — context-process
# =============================================================================

output "service_account_email" {
  description = "SA del contexto process"
  value       = google_service_account.process_functions_sa.email
}

output "source_bucket_name" {
  description = "Bucket con el código fuente de context-process"
  value       = google_storage_bucket.process_source_code.name
}

output "pubsub_topic_name" {
  description = "Nombre del topic poc-test-topic (usado por context-root para publicar)"
  value       = google_pubsub_topic.poc_test_topic.name
}

output "pubsub_topic_id" {
  description = "ID completo del topic poc-test-topic"
  value       = google_pubsub_topic.poc_test_topic.id
}

output "tasks_queue_name" {
  description = "Nombre de la cola Cloud Tasks"
  value       = google_cloud_tasks_queue.poc_test_queue.name
}

output "pubsub_handler_url" {
  description = "URL de poc-pubsub-handler"
  value       = google_cloudfunctions2_function.poc_pubsub_handler.service_config[0].uri
}

output "task_handler_url" {
  description = "URL de poc-task-handler"
  value       = google_cloudfunctions2_function.poc_task_handler.service_config[0].uri
}
