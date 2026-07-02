-- =====================================================
-- HELPDESK / HELPERS DE INTEGRACIÓN Y LEGACY
-- =====================================================
-- Objetivo:
--   Agrupar tablas auxiliares para:
--
--   1. PostgreSQL -> SharePoint HelpDeskBd mediante outbox.
--   2. Control de inconsistencias legacy detectadas durante ETL.
--   3. Reglas data-driven para mapear combinaciones legacy de tipo
--      de requerimiento hacia el catálogo canónico.
--
-- Nota:
--   Este archivo NO contiene transformaciones masivas.
--   Las transformaciones viven en archivos separados:
--     01_transform_area.sql
--     02_transform_clientes.sql
--     ...
--     07_transform_ticket_evento.sql
-- =====================================================


-- =====================================================
-- 1. OUTBOX: POSTGRESQL -> SHAREPOINT
-- =====================================================
-- Controla el flujo PostgreSQL -> SharePoint HelpDeskBd -> PowerApps.
--
-- Estados:
--   PENDING    : listo para ser reclamado por n8n.
--   PROCESSING : reclamado por n8n.
--   SENT       : creado/actualizado correctamente.
--   FAILED     : error real, requiere revisión o reintento controlado.
-- =====================================================

CREATE TABLE IF NOT EXISTS helpdesk.ticket_sync_outbox (
    id_sync UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    id_ticket UUID NOT NULL
        REFERENCES helpdesk.fact_ticket(id_ticket)
        ON DELETE CASCADE,

    target_system TEXT NOT NULL DEFAULT 'SHAREPOINT',

    operation TEXT NOT NULL,

    status TEXT NOT NULL DEFAULT 'PENDING',

    payload JSONB NOT NULL DEFAULT '{}'::jsonb,

    attempts INTEGER NOT NULL DEFAULT 0,

    last_error TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMPTZ,

    CONSTRAINT chk_ticket_sync_outbox_target
    CHECK (target_system IN ('SHAREPOINT')),

    CONSTRAINT chk_ticket_sync_outbox_operation
    CHECK (operation IN (
        'CREATE_TICKET',
        'UPDATE_TICKET',
        'CANCEL_TICKET'
    )),

    CONSTRAINT chk_ticket_sync_outbox_status
    CHECK (status IN (
        'PENDING',
        'PROCESSING',
        'SENT',
        'FAILED'
    )),

    CONSTRAINT chk_ticket_sync_outbox_attempts
    CHECK (attempts >= 0)
);

CREATE INDEX IF NOT EXISTS ix_ticket_sync_outbox_status_created
ON helpdesk.ticket_sync_outbox(status, created_at);

CREATE INDEX IF NOT EXISTS ix_ticket_sync_outbox_ticket
ON helpdesk.ticket_sync_outbox(id_ticket);

CREATE UNIQUE INDEX IF NOT EXISTS uq_ticket_sync_outbox_pending_operation
ON helpdesk.ticket_sync_outbox(id_ticket, operation)
WHERE status IN ('PENDING', 'PROCESSING');


-- =====================================================
-- 2. CLIENTES CONFLICTIVOS DESDE SHAREPOINT
-- =====================================================
-- Registra NITs con nombres materialmente distintos en SharePoint.
--
-- La transformación de clientes no debe escoger a ciegas en estos casos.
-- El conflicto se deja visible para revisión.
-- =====================================================

CREATE TABLE IF NOT EXISTS staging.sp_clientes_contai_conflict (
    identificacion_fiscal TEXT PRIMARY KEY,
    conflict_reason TEXT NOT NULL,
    payloads JSONB NOT NULL,
    detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_dim_cliente_contai_identificacion_fiscal_not_null
ON core.dim_cliente_contai (identificacion_fiscal)
WHERE identificacion_fiscal IS NOT NULL;


-- =====================================================
-- 3. TIPO DE REQUERIMIENTO LEGACY NO MAPEADO
-- =====================================================
-- Captura tickets SHAREPOINT_LEGACY cuyo area/tipo/categorias históricas
-- no pudieron resolverse contra helpdesk.dim_tipo_requerimiento.
--
-- Esta tabla NO corrige datos.
-- Sirve para monitoreo, auditoría y diseño de reglas.
-- =====================================================

CREATE TABLE IF NOT EXISTS staging.helpdesk_legacy_tipo_req_unmapped (
    sp_id INTEGER PRIMARY KEY,
    id_ticket UUID NOT NULL,
    codigo_ticket TEXT NOT NULL,
    legacy_id_req TEXT,
    area_original TEXT,
    tipo_original TEXT,
    categoria_1_original TEXT,
    categoria_2_original TEXT,
    requerimiento TEXT,
    fecha_creacion TIMESTAMPTZ,
    first_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    occurrence_count INTEGER NOT NULL DEFAULT 1
);


-- =====================================================
-- 4. REGLAS DE MAPPING PARA TIPOS DE REQUERIMIENTO LEGACY
-- =====================================================
-- Reglas por patrón legacy, no por ticket.
--
-- Ejemplo:
--   ADMINISTRACIÓN-RECEPCIÓN / OTROS / OTROS / NULL
--   -> ADMINISTRACIÓN-RECEPCIÓN / OTROS / NULL / NULL
--
-- Ventajas:
--   - Evita manualidad por ticket.
--   - Evita clasificaciones falsas no auditadas.
--   - Permite corregir el ETL sin hardcodear todos los casos en SQL.
-- =====================================================

CREATE TABLE IF NOT EXISTS staging.helpdesk_legacy_tipo_req_mapping_rule (
    id_rule UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    source_area_norm TEXT NOT NULL,
    source_tipo_norm TEXT,
    source_categoria_1_norm TEXT,
    source_categoria_2_norm TEXT,

    target_area_norm TEXT NOT NULL,
    target_tipo_norm TEXT NOT NULL,
    target_categoria_1_norm TEXT,
    target_categoria_2_norm TEXT,

    reason TEXT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    priority INTEGER NOT NULL DEFAULT 100,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_helpdesk_legacy_tipo_req_mapping_rule_source
ON staging.helpdesk_legacy_tipo_req_mapping_rule (
    source_area_norm,
    COALESCE(source_tipo_norm, ''),
    COALESCE(source_categoria_1_norm, ''),
    COALESCE(source_categoria_2_norm, '')
);


-- =====================================================
-- 5. SEED DE REGLAS LEGACY APROBADAS
-- =====================================================
-- Regla segura detectada en migración:
--
-- SharePoint histórico:
--   ADMINISTRACIÓN-RECEPCIÓN / OTROS / OTROS / NULL
--
-- Catálogo canónico:
--   ADMINISTRACIÓN-RECEPCIÓN / OTROS / NULL / NULL
-- =====================================================

INSERT INTO staging.helpdesk_legacy_tipo_req_mapping_rule (
    source_area_norm,
    source_tipo_norm,
    source_categoria_1_norm,
    source_categoria_2_norm,
    target_area_norm,
    target_tipo_norm,
    target_categoria_1_norm,
    target_categoria_2_norm,
    reason,
    active,
    priority
)
VALUES (
    core.norm_text('ADMINISTRACIÓN-RECEPCIÓN'),
    core.norm_text('OTROS'),
    core.norm_text('OTROS'),
    NULL,
    core.norm_text('ADMINISTRACIÓN-RECEPCIÓN'),
    core.norm_text('OTROS'),
    NULL,
    NULL,
    'Regla legacy: SharePoint registraba ADMINISTRACIÓN-RECEPCIÓN / OTROS / OTROS, pero el catálogo actual representa OTROS sin categorías.',
    TRUE,
    10
)
ON CONFLICT (
    source_area_norm,
    COALESCE(source_tipo_norm, ''),
    COALESCE(source_categoria_1_norm, ''),
    COALESCE(source_categoria_2_norm, '')
)
DO UPDATE SET
    target_area_norm = EXCLUDED.target_area_norm,
    target_tipo_norm = EXCLUDED.target_tipo_norm,
    target_categoria_1_norm = EXCLUDED.target_categoria_1_norm,
    target_categoria_2_norm = EXCLUDED.target_categoria_2_norm,
    reason = EXCLUDED.reason,
    active = TRUE,
    priority = EXCLUDED.priority,
    updated_at = NOW();