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
