# =============================================================================
# outputs.tf — context-root
# =============================================================================

output "service_account_email" {
  description = "SA del contexto root"
  value       = google_service_account.root_functions_sa.email
}

output "source_bucket_name" {
  description = "Bucket con el código fuente de context-root"
  value       = google_storage_bucket.root_source_code.name
}

output "firestore_listener_url" {
  description = "URL de poc-firestore-listener"
  value       = google_cloudfunctions2_function.poc_firestore_listener.service_config[0].uri
}
