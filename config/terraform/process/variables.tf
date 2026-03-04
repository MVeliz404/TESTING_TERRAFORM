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

variable "terraform_sa" {
  description = "Service Account que Terraform impersona para desplegar. Tu cuenta personal necesita roles/iam.serviceAccountTokenCreator sobre ella."
  type        = string
}

variable "sa_email" {
  description = "Email de la SA que ejecutará las Cloud Functions (gestionada manualmente en GCP)"
  type        = string
}
