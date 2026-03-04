# =============================================================================
# variables.tf — context-root
# =============================================================================

variable "project_id" {
  description = "ID del proyecto GCP"
  type        = string
}

variable "region" {
  description = "Región de despliegue"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Ambiente: dev, cert, prod"
  type        = string
}

# Nombre del topic Pub/Sub al que publica poc-firestore-listener.
# El topic es propiedad de context-process — aquí se referencia solo por nombre.
# Si process no está desplegado, la función fallará en runtime al publicar,
# pero el despliegue de root no depende de ello.
variable "output_topic_name" {
  description = "Nombre del topic Pub/Sub destino (declarado en context-process)"
  type        = string
  default     = "poc-test-topic"
}

# Región de la base de datos Firestore.
# IMPORTANTE: es independiente de var.region (región de la Cloud Function).
# El trigger_region del Eventarc Firestore debe coincidir con la región
# donde existe la database, no con la región de despliegue de la función.
# Valores comunes: "nam5" (US multi-región), "eur3" (Europa), "us-central1".
# Consultar con: gcloud firestore databases list
variable "terraform_sa" {
  description = "Service Account que Terraform impersona para desplegar. Tu cuenta personal necesita roles/iam.serviceAccountTokenCreator sobre ella."
  type        = string
}

variable "sa_email" {
  description = "Email de la SA que ejecutará las Cloud Functions (gestionada manualmente en GCP)"
  type        = string
}

variable "firestore_location" {
  description = "Región de la base de datos Firestore (para el trigger Eventarc)"
  type        = string
  default     = "nam5"
}
