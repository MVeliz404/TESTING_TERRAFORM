# =============================================================================
# variables.tf — context-process
# =============================================================================

variable "project_id" {
  description = "ID del proyecto GCP"
  type        = string
}

variable "region" {
  description = "Región de despliegue"
  type        = string
}

variable "environment" {
  description = "Ambiente: dev, cert, prod"
  type        = string
}
