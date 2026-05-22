# Decisiones Técnicas

## DT-001 — Staging JSONB por lista SharePoint

Se conserva payload crudo por `sp_id` en tablas `staging.sp_*_raw`.

Motivo:
- preservar fuente original
- permitir reprocesar transformaciones
- evitar depender del chat o n8n para reconstruir datos

## DT-002 — `dim_tipo_requerimiento` usa `id_area`

Se elimina concepto `nombre_tipo`.

Motivo:
- `TipoReqHD.Title` representa área
- el área debe relacionarse con `core.dim_area`
- evita duplicar texto semánticamente incorrecto

## DT-003 — `UNIQUE NULLS NOT DISTINCT`

La clave natural de tipo requerimiento es:

- `id_area`
- `tipo_requerimiento`
- `categoria_1`
- `categoria_2`

Se usa `UNIQUE NULLS NOT DISTINCT` para impedir duplicados lógicos con NULL.

## DT-004 — `event_hash` en eventos inferidos

Los eventos legacy inferidos desde columnas no tienen `sp_event_id`.

Se usa `event_hash` para idempotencia.

## DT-005 — No forzar clasificación de tickets incompletos

Los tickets sin información suficiente quedan con `id_tipo_req = NULL`.

Motivo:
- preservar integridad
- evitar clasificaciones inventadas