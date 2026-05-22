-- =====================================================
-- 5. HELPDESK / FACT TICKET
-- =====================================================
CREATE TABLE helpdesk.fact_ticket (
    id_ticket UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- ID original del ítem en SharePoint HelpDeskBd.
    consecutivo_sp INTEGER NOT NULL UNIQUE,

    titulo_ticket VARCHAR(255) NOT NULL,
    descripcion_problema TEXT NOT NULL,

    -- Identidad de origen.
    -- Regla: exactamente uno debe existir:
    -- cliente externo OR empleado interno.
    id_cliente_contai UUID REFERENCES core.dim_cliente_contai(id_cliente_contai),
    id_solicitante UUID REFERENCES core.dim_personal(id_personal),

    -- Operación interna
    id_area_destino UUID REFERENCES core.dim_area(id_area),
    id_asignado UUID REFERENCES core.dim_personal(id_personal),

    -- Clasificación
    id_estado UUID NOT NULL REFERENCES helpdesk.dim_estado(id_estado),
    id_prioridad UUID REFERENCES helpdesk.dim_prioridad(id_prioridad),
    id_tipo_req UUID REFERENCES helpdesk.dim_tipo_requerimiento(id_tipo_req),

    -- Tiempos
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_limite TIMESTAMPTZ,
    fecha_resolucion TIMESTAMPTZ,

    -- Cierre
    respuesta_final TEXT,
    calificacion INTEGER,

    ultima_actualizacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),

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

    CONSTRAINT chk_fact_ticket_fechas_validas
    CHECK (
        fecha_resolucion IS NULL
        OR fecha_resolucion >= fecha_creacion
    ),

    CONSTRAINT chk_fact_ticket_calificacion
    CHECK (
        calificacion IS NULL
        OR calificacion BETWEEN 1 AND 5
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