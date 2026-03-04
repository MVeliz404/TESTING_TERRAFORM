# =============================================================================
# backend.tf — Configuración PARCIAL del backend (contexto: process)
#
# ARQUITECTURA REAL (3 proyectos GCP — uno por ambiente):
#   El aislamiento dev/cert/prod lo da el PROYECTO GCP, no el prefix.
#   El prefix solo diferencia contextos dentro del mismo proyecto.
#
#   Proyecto GCP dev  → gs://tfstate-plg11-lct/process/default.tfstate
#   Proyecto GCP cert → gs://tfstate-plg11-lct/process/default.tfstate
#   Proyecto GCP prod → gs://tfstate-plg11-lct/process/default.tfstate
#
#   terraform init -backend-config="prefix=process"   (en cualquier proyecto)
#
# ARQUITECTURA POC (1 proyecto GCP — ambiente en el prefix):
#   El prefix incluye el ambiente porque todo está en el mismo proyecto.
#
#   terraform init -backend-config="prefix=dev/process"
#   terraform init -backend-config="prefix=cert/process"
# =============================================================================

terraform {
  backend "gcs" {
    bucket = "tfstate-poc-matiaslab"
    # prefix: NO se define aquí — se pasa en terraform init via -backend-config
  }
}