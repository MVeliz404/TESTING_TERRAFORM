import json
import functions_framework


@functions_framework.http
def cloud_function(request):
    """
    Invocada por Cloud Tasks vía HTTP POST con autenticación OIDC.
    1. Imprime el payload recibido.
    2. Retorna 200 OK para que Cloud Tasks no reintente la tarea.
    """
    print("=" * 60)
    print("POC-TASK-HANDLER: Tarea recibida de Cloud Tasks")
    print(f"Method : {request.method}")
    print(f"Headers: {dict(request.headers)}")

    # Leer body de la petición
    try:
        body_raw = request.get_data(as_text=True)
        print(f"Body (raw): {body_raw}")

        if body_raw:
            body = json.loads(body_raw)
            print(f"Body (parsed):")
            print(json.dumps(body, indent=2, default=str))
        else:
            print("Body vacío — la tarea no trajo payload.")
    except Exception as e:
        print(f"Error al parsear el body: {e}")

    print("POC-TASK-HANDLER: Procesamiento completado — retornando 200")
    print("=" * 60)

    return (
        json.dumps({"status": "ok", "message": "Tarea procesada por poc-task-handler"}),
        200,
        {"Content-Type": "application/json"},
    )
