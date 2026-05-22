# Estrategia de Transición CORAJE

## Principio

No se elimina PowerApps al inicio. Se estrangula progresivamente.

## Estado inicial

PowerApps sigue operando sobre SharePoint.
Next.js se introduce primero para clientes externos.

## Flujo cliente inicial

Cliente -> Next.js -> PostgreSQL -> n8n -> SharePoint -> PowerApps visible para empleados.

## Flujo empleado legacy

Empleado -> PowerApps -> SharePoint -> n8n incremental -> PostgreSQL.

## Objetivo posterior

Next.js reemplaza gradualmente PowerApps para empleados.

## Criterio para apagar PowerApps

PowerApps solo se retira cuando:
- Next.js cubra creación, asignación, respuesta, cierre y rechazo.
- empleados lo usen sin fricción.
- existan métricas de estabilidad.
- SharePoint ya no sea fuente operativa principal.