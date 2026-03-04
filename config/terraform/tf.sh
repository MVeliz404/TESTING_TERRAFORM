#!/usr/bin/env bash
# =============================================================================
# tf.sh — Wrapper de Terraform para la PoC PLG11-LCT
#
# Uso:
#   ./tf.sh <contexto> <ambiente> <acción>
#
# Ejemplos:
#   ./tf.sh process dev init
#   ./tf.sh process dev plan
#   ./tf.sh process dev apply
#   ./tf.sh root    dev plan
#   ./tf.sh root    dev apply
#   ./tf.sh process dev destroy
#
# Contextos válidos : root | process
# Ambientes válidos : dev | cert | prod
# Acciones válidas  : init | plan | apply | destroy
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Argumentos
# ---------------------------------------------------------------------------
CONTEXT="${1:-}"
ENV="${2:-}"
ACTION="${3:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTEXT_DIR="${SCRIPT_DIR}/${CONTEXT}"
TFVARS="${SCRIPT_DIR}/environment/terraform.${ENV}.tfvars"
PLAN_FILE="${CONTEXT_DIR}/plan.tfplan"

# ---------------------------------------------------------------------------
# Validaciones
# ---------------------------------------------------------------------------
if [[ -z "$CONTEXT" || -z "$ENV" || -z "$ACTION" ]]; then
  echo "Uso: ./tf.sh <contexto> <ambiente> <acción>"
  echo "  Contextos : root | process"
  echo "  Ambientes : dev | cert | prod"
  echo "  Acciones  : init | plan | apply | destroy"
  exit 1
fi

if [[ ! "$CONTEXT" =~ ^(root|process)$ ]]; then
  echo "Error: contexto '$CONTEXT' no válido. Usa: root | process"
  exit 1
fi

if [[ ! "$ENV" =~ ^(dev|cert|prod)$ ]]; then
  echo "Error: ambiente '$ENV' no válido. Usa: dev | cert | prod"
  exit 1
fi

if [[ ! "$ACTION" =~ ^(init|plan|apply|destroy)$ ]]; then
  echo "Error: acción '$ACTION' no válida. Usa: init | plan | apply | destroy"
  exit 1
fi

if [[ ! -d "$CONTEXT_DIR" ]]; then
  echo "Error: directorio '$CONTEXT_DIR' no existe."
  exit 1
fi

if [[ "$ACTION" != "init" && ! -f "$TFVARS" ]]; then
  echo "Error: archivo de variables '$TFVARS' no encontrado."
  echo "Crea el archivo o verifica el ambiente especificado."
  exit 1
fi

# ---------------------------------------------------------------------------
# Ejecución
# ---------------------------------------------------------------------------
echo ""
echo "╔══════════════════════════════════════════╗"
echo "  Contexto : $CONTEXT"
echo "  Ambiente : $ENV"
echo "  Acción   : $ACTION"
echo "╚══════════════════════════════════════════╝"
echo ""

cd "$CONTEXT_DIR"

case "$ACTION" in

  init)
    echo "→ terraform init (prefix=${CONTEXT})"
    terraform init -backend-config="prefix=${CONTEXT}" -reconfigure
    ;;

  plan)
    echo "→ terraform fmt + validate"
    terraform fmt -check -recursive
    terraform validate
    echo "→ terraform plan → ${PLAN_FILE}"
    terraform plan -var-file="$TFVARS" -out="$PLAN_FILE"
    echo ""
    echo "Plan guardado en: $PLAN_FILE"
    echo "Para aplicar: ./tf.sh $CONTEXT $ENV apply"
    ;;

  apply)
    if [[ ! -f "$PLAN_FILE" ]]; then
      echo "Error: no existe plan.tfplan en '$CONTEXT_DIR'."
      echo "Ejecuta primero: ./tf.sh $CONTEXT $ENV plan"
      exit 1
    fi
    echo "→ terraform apply"
    terraform apply "$PLAN_FILE"
    rm -f "$PLAN_FILE"
    echo ""
    echo "→ terraform output"
    terraform output
    ;;

  destroy)
    echo "ADVERTENCIA: esto destruirá todos los recursos del contexto '$CONTEXT' en '$ENV'."
    read -r -p "¿Confirmas? (escribe 'si' para continuar): " CONFIRM
    if [[ "$CONFIRM" != "si" ]]; then
      echo "Cancelado."
      exit 0
    fi
    terraform destroy -var-file="$TFVARS"
    ;;

esac

echo ""
echo "✓ Completado: $ACTION / $CONTEXT / $ENV"
