# Terraform PoC — PLG11-LCT

Prueba de concepto para validar el despliegue de infraestructura GCP con Terraform,
organizada en dos contextos independientes que replican la estructura del proyecto real.

---

## Estructura

```
config/terraform/
  environment/          ← Variables por ambiente (NO se suben al repo)
    terraform.dev.tfvars
    terraform.cert.tfvars
    terraform.prod.tfvars
  root/                 ← Contexto root  │ state: gs://tfstate-poc-matiaslab/{env}/root/
    poc-firestore-listener (Eventarc Firestore → publica en Pub/Sub)
  process/              ← Contexto process │ state: gs://tfstate-poc-matiaslab/{env}/process/
    poc-test-topic (Pub/Sub)
    poc-test-queue (Cloud Tasks)
    poc-pubsub-handler  (Eventarc Pub/Sub → encola tarea)
    poc-task-handler    (HTTP ← Cloud Tasks)

functions/
  context-root/
    poc-firestore-listener/   main.py + requirements.txt
  context-process/
    poc-pubsub-handler/       main.py + requirements.txt
    poc-task-handler/         main.py + requirements.txt
```

---

## Prerrequisitos

Antes del primer `terraform apply`:

```bash
# 1. Autenticarse con tu cuenta personal (con permisos de Editor)
gcloud auth application-default login

# 2. Verificar proyecto activo
gcloud config get-value project

# 3. Habilitar las APIs necesarias (solo una vez por proyecto)
gcloud services enable cloudfunctions.googleapis.com run.googleapis.com \
  cloudbuild.googleapis.com pubsub.googleapis.com cloudtasks.googleapis.com \
  eventarc.googleapis.com firestore.googleapis.com storage.googleapis.com \
  iam.googleapis.com artifactregistry.googleapis.com \
  cloudresourcemanager.googleapis.com

# 4. Verificar que el bucket de estado existe
gcloud storage ls gs://tfstate-poc-matiaslab
```

---

## Despliegue

> Desplegar **siempre process primero** — es dueño del topic Pub/Sub que usa root.

Usa el script `tf.sh` desde `config/terraform/`:

```bash
# Sintaxis
./tf.sh <contexto> <ambiente> <acción>

# Contextos : root | process
# Ambientes : dev | cert | prod
# Acciones  : init | plan | apply | destroy
```

### Flujo completo (primera vez)

```bash
cd config/terraform/

# 1. Inicializar ambos contextos
./tf.sh process dev init
./tf.sh root    dev init

# 2. Planificar (genera plan.tfplan en cada contexto)
./tf.sh process dev plan
./tf.sh root    dev plan

# 3. Aplicar
./tf.sh process dev apply
./tf.sh root    dev apply
```

### Cambiar de ambiente

```bash
./tf.sh process cert init
./tf.sh process cert plan
./tf.sh process cert apply
```

### Destruir

```bash
# Orden inverso al despliegue
./tf.sh root    dev destroy
./tf.sh process dev destroy
```

### Comandos manuales (sin script)

<details>
<summary>Expandir</summary>

```bash
cd config/terraform/process/
terraform init -backend-config="prefix=dev/process"
terraform fmt && terraform validate
terraform plan -var-file="../environment/terraform.dev.tfvars" -out=plan.tfplan
terraform apply plan.tfplan
```

</details>

---

## Verificar outputs

```bash
# Desde cualquier contexto después del apply
terraform output
```

Muestra URLs de las funciones, SA, bucket, topic y cola.

---

## Prueba end-to-end

Una vez desplegados ambos contextos, crea un documento en Firestore para disparar el flujo:

```bash
ACCESS_TOKEN=$(gcloud auth print-access-token)
PROJECT_ID="matiaslab-4e979"

curl -X PATCH \
  "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/poc_test_events/test-$(date +%s)" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "mensaje": {"stringValue": "hola desde curl"},
      "timestamp": {"stringValue": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"}
    }
  }'
```

Verificar logs de las 3 funciones (~30 segundos después):

```bash
gcloud functions logs read poc-firestore-listener --region=us-central1 --limit=20
gcloud functions logs read poc-pubsub-handler     --region=us-central1 --limit=20
gcloud functions logs read poc-task-handler       --region=us-central1 --limit=20
```

Flujo esperado: `Firestore write → CF1 → Pub/Sub → CF2 → Cloud Tasks → CF3`

---

## Destruir recursos

```bash
# Destruir un contexto (el apply inverso)
terraform destroy -var-file="../environment/terraform.dev.tfvars"
```

> Destruir `process` antes que `root` si eliminas ambos, para respetar el orden inverso.

---

## Notas

| Tema | Detalle |
|---|---|
| State locking | GCS aplica locks nativos — dos `apply` en el mismo prefix se bloquean entre sí |
| Paralelismo | Dos devs pueden operar `root` y `process` simultáneamente sin conflicto |
| Código Python | Cambiar un `.py` y re-aplicar redesplega solo la función afectada (hash MD5 en nombre del ZIP) |
| `.tfvars` | No se suben al repo — contienen el `project_id` real. Copiar y editar localmente |
| `output_topic_name` en root | Variable con default `"poc-test-topic"` — coincide con el topic declarado en process |
