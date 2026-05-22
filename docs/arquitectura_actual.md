# Proyecto CORAJE — Arquitectura Actual

## Objetivo

Migración one-way desde SharePoint hacia PostgreSQL, usando patrón Strangler Fig.

## Stack actual

- PostgreSQL 16 Alpine
- Docker Compose
- n8n local
- n8n Cloud como proxy/bridge de ingesta
- Next.js/Tailwind proyectado para frontend
- Coolify proyectado para despliegue

## Flujo de datos

SharePoint -> n8n Cloud -> n8n Local -> staging JSONB -> transform SQL -> core/helpdesk

## Esquemas

- staging: payloads crudos SharePoint
- core: dimensiones maestras reutilizables
- helpdesk: modelo funcional del helpdesk

## Principio de migración

SharePoint es fuente legacy. PostgreSQL se convierte en fuente estructurada. Migración one-way.