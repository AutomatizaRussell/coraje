-- =====================================================
-- HELPDESK / FACT TICKET
-- Tabla canónica del ticket dentro de PostgreSQL.
--
-- Esta tabla NO depende de SharePoint para existir.
-- SharePoint queda como sistema legacy externo.
--
-- Identidad:
--   - id_ticket: identificador técnico interno, usado por FKs.
--   - codigo_ticket: identificador visible/operativo para usuarios.
--
-- NO se conserva:
--   - consecutivo_sp: ID técnico interno de SharePoint.
--   - titulo_ticket: estaba siendo usado incorrectamente como Id_Req.
-- =====================================================
CREATE TABLE helpdesk.fact_ticket (
    -- Identificador técnico interno.
    -- No se expone como código humano principal.
    id_ticket UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Código visible del ticket.
    -- Reemplaza funcionalmente al Id_Req legacy, pero generado por PostgreSQL.
    -- Ejemplo esperado: HD-2026-000001.
    codigo_ticket TEXT NOT NULL UNIQUE DEFAULT helpdesk.next_codigo_ticket(),

    -- Texto principal del requerimiento.
    -- En SharePoint legacy venía de la columna Requerimiento.
    descripcion_problema TEXT NOT NULL,

    -- Identidad de origen humano.
    -- Regla: exactamente uno debe existir:
    --   - cliente externo: id_cliente_contai
    --   - empleado interno: id_solicitante
    id_cliente_contai UUID REFERENCES core.dim_cliente_contai(id_cliente_contai),
    id_solicitante UUID REFERENCES core.dim_personal(id_personal),

    -- Operación interna.
    -- Pueden estar NULL al momento de creación si el ticket aún no fue redirigido/asignado.
    id_area_destino UUID REFERENCES core.dim_area(id_area),
    id_asignado UUID REFERENCES core.dim_personal(id_personal),

    -- Clasificación funcional.
    id_estado UUID NOT NULL REFERENCES helpdesk.dim_estado(id_estado),
    id_prioridad UUID REFERENCES helpdesk.dim_prioridad(id_prioridad),
    id_tipo_req UUID REFERENCES helpdesk.dim_tipo_requerimiento(id_tipo_req),

    -- Tiempos.
    -- fecha_creacion: momento real en que el ticket entra a PostgreSQL o se migra desde legacy.
    -- fecha_limite: fecha máxima de respuesta calculada según SLA/calendario.
    -- fecha_resolucion: fecha de cierre/respuesta final.
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_limite TIMESTAMPTZ,
    fecha_resolucion TIMESTAMPTZ,

    -- Cierre.
    respuesta_final TEXT,
    calificacion INTEGER,

    -- Origen funcional del ticket.
    --
    -- SHAREPOINT_LEGACY:
    --   Ticket importado desde la lista HelpDeskBd.
    --
    -- PORTAL_CLIENTE:
    --   Ticket creado desde el nuevo portal Next.js.
    --
    -- POSTGRES:
    --   Caso genérico para creación directa por proceso interno de base de datos.
    --   Si no existe este caso real, recomiendo renombrarlo a SISTEMA_INTERNO
    --   o eliminarlo del CHECK.
    origen_sistema TEXT NOT NULL,

    -- Última actualización controlada por PostgreSQL/ETL/app.
    ultima_actualizacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Garantiza que el ticket venga de exactamente un origen humano:
    -- cliente externo OR empleado interno.
    CONSTRAINT chk_fact_ticket_origen_exclusivo
    CHECK (
        (
            id_cliente_contai IS NOT NULL
            AND id_solicitante IS NULL
        )
        OR
        (
            id_cliente_contai IS NULL
            AND id_solicitante IS NOT NULL
        )
    ),

    -- Evita cierres anteriores a la creación.
    CONSTRAINT chk_fact_ticket_fechas_validas
    CHECK (
        fecha_resolucion IS NULL
        OR fecha_resolucion >= fecha_creacion
    ),

    -- Calificación válida únicamente entre 1 y 5.
    CONSTRAINT chk_fact_ticket_calificacion
    CHECK (
        calificacion IS NULL
        OR calificacion BETWEEN 1 AND 5
    ),

    -- Origen permitido.
    -- Recomendación: cambiar POSTGRES por SISTEMA_INTERNO si quieres semántica más limpia.
    CONSTRAINT chk_fact_ticket_origen_sistema
    CHECK (
        origen_sistema IN (
            'SHAREPOINT_LEGACY',
            'PORTAL_CLIENTE',
            'SISTEMA_INTERNO'
        )
    )
);


-- =====================================================
-- 6. HELPDESK / EVENTOS DEL TICKET
-- =====================================================
CREATE TABLE helpdesk.fact_ticket_evento (
    id_evento UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- ID original de evento/comentario en SharePoint, si algún día se extraen
    -- eventos reales desde una lista/histórico con ID propio.
    sp_event_id INTEGER UNIQUE,

    -- Llave determinística para eventos inferidos desde columnas del ticket.
    -- Ejemplos:
    --   Justifique_Prioridad
    --   Comentarios_adicionales
    --   Observaci_x00f3_n
    --   Respuesta_Sugerida
    --
    -- Se usa para que la transformación sea idempotente:
    -- correr el ETL varias veces no debe duplicar el mismo evento.
    event_hash TEXT UNIQUE,

    id_ticket UUID NOT NULL REFERENCES helpdesk.fact_ticket(id_ticket) ON DELETE CASCADE,
    id_autor UUID REFERENCES core.dim_personal(id_personal),

    tipo_evento VARCHAR(50) NOT NULL,
    contenido TEXT NOT NULL,

    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_fact_ticket_evento_tipo
    CHECK (
        tipo_evento IN (
            'COMENTARIO',
            'REASIGNACION',
            'CAMBIO_ESTADO',
            'MIGRACION_LEGACY'
        )
    )
);


-- =====================================================
-- HELPDESK / REFERENCIA LEGACY SHAREPOINT
--
-- Tabla puente temporal entre PostgreSQL canónico y SharePoint.
--
-- Guarda:
--   - sp_id: ID interno del ítem en SharePoint.
--   - legacy_id_req: Id_Req viejo generado por PowerApps.
--   - legacy_title: Title de SharePoint, que realmente es correo.
--   - legacy_created_at: Created original de SharePoint.
--
-- Esta tabla puede eliminarse cuando SharePoint/PowerApps mueran.
-- =====================================================
-- =====================================================
-- HELPDESK / REFERENCIA LEGACY SHAREPOINT
--
-- Tabla puente temporal entre PostgreSQL canónico y SharePoint.
--
-- Guarda:
--   - sp_id: ID interno del ítem en SharePoint.
--   - legacy_id_req: Id_Req viejo generado por PowerApps.
--   - legacy_title: Title de SharePoint, que realmente es correo.
--   - legacy_created_at: Created original de SharePoint.
--
-- Esta tabla puede eliminarse cuando SharePoint/PowerApps mueran.
-- =====================================================
CREATE TABLE helpdesk.ticket_legacy_sharepoint_ref (
    -- FK al ticket canónico.
    -- No genera id_ticket.
    -- El id_ticket debe venir desde helpdesk.fact_ticket.
    id_ticket UUID PRIMARY KEY,

    -- ID interno autogenerado por SharePoint.
    -- No pertenece al dominio canónico.
    sp_id INTEGER NOT NULL UNIQUE,

    -- Id_Req legacy de PowerApps.
    -- No es unique porque ya existe al menos un duplicado.
    legacy_id_req TEXT,

    -- Title de SharePoint.
    -- En la evidencia actual corresponde al correo del creador.
    legacy_title TEXT,

    -- Fecha Created original de SharePoint.
    legacy_created_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_ticket_legacy_sharepoint_ref_ticket
    FOREIGN KEY (id_ticket)
    REFERENCES helpdesk.fact_ticket(id_ticket)
    ON DELETE CASCADE

);