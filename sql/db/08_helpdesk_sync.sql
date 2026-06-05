-- =====================================================
-- HELPDESK / COLA DE SINCRONIZACIÓN
-- =====================================================
-- Objetivo:
--   Controlar el flujo PostgreSQL → SharePoint HelpDeskBd → PowerApps.
--
-- Uso:
--   Cuando un ticket de portal queda listo para enviarse a SharePoint,
--   se inserta un registro PENDING.
--
-- n8n procesa:
--   PENDING → PROCESSING → SENT / FAILED
--
-- No reemplaza fact_ticket. Solo controla integración.
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