# =============================================================================
# storage.tf — context-root
# Bucket de código fuente + empaquetado de poc-firestore-listener
#
# path.module = config/terraform/root/
# Ruta a funciones: ../../../functions/context-root/<nombre-función>
# =============================================================================

resource "google_storage_bucket" "root_source_code" {
  name          = "${var.project_id}-poc-root-source"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true
}

data "archive_file" "poc_firestore_listener" {
  type        = "zip"
  source_dir  = "${path.module}/../../../functions/context-root/poc-firestore-listener"
  output_path = "${path.module}/.build/poc-firestore-listener.zip"
}

resource "google_storage_bucket_object" "poc_firestore_listener" {
  name   = "poc-firestore-listener-${data.archive_file.poc_firestore_listener.output_md5}.zip"
  bucket = google_storage_bucket.root_source_code.name
  source = data.archive_file.poc_firestore_listener.output_path
}
