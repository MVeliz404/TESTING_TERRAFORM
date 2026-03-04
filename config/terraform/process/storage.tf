# =============================================================================
# storage.tf — context-process
# Bucket de código fuente + empaquetado de poc-pubsub-handler y poc-task-handler
#
# path.module = config/terraform/process/
# Ruta a funciones: ../../../functions/context-process/<nombre-función>
# =============================================================================

resource "google_storage_bucket" "process_source_code" {
  name          = "${var.project_id}-poc-process-source"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true
}

# --------------------------------------------------------------------------
# poc-pubsub-handler
# --------------------------------------------------------------------------
data "archive_file" "poc_pubsub_handler" {
  type        = "zip"
  source_dir  = "${path.module}/../../../functions/context-process/poc-pubsub-handler"
  output_path = "${path.module}/.build/poc-pubsub-handler.zip"
}

resource "google_storage_bucket_object" "poc_pubsub_handler" {
  name   = "poc-pubsub-handler-${data.archive_file.poc_pubsub_handler.output_md5}.zip"
  bucket = google_storage_bucket.process_source_code.name
  source = data.archive_file.poc_pubsub_handler.output_path
}

# --------------------------------------------------------------------------
# poc-task-handler
# --------------------------------------------------------------------------
data "archive_file" "poc_task_handler" {
  type        = "zip"
  source_dir  = "${path.module}/../../../functions/context-process/poc-task-handler"
  output_path = "${path.module}/.build/poc-task-handler.zip"
}

resource "google_storage_bucket_object" "poc_task_handler" {
  name   = "poc-task-handler-${data.archive_file.poc_task_handler.output_md5}.zip"
  bucket = google_storage_bucket.process_source_code.name
  source = data.archive_file.poc_task_handler.output_path
}
