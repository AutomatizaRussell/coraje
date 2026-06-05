-- =====================================================
-- HELPDESK / FACTS, EVENTOS, REFERENCIAS Y REGLAS
-- =====================================================
-- Este archivo define:
--
--   1. helpdesk.fact_ticket
--      Tabla canónica del ticket dentro de PostgreSQL.
--
--   2. helpdesk.fact_ticket_evento
--      Timeline/eventos asociados al ticket.
--
--   3. helpdesk.ticket_legacy_sharepoint_ref
--      Puente temporal entre el ticket canónico y SharePoint/PowerApps.
--
--   4. helpdesk.routing_rule
--      Reglas explícitas para resolver encargado interno por tipo/categoría.
--
-- Nota:
--   La cola de sincronización PostgreSQL -> SharePoint debe vivir en otro
--   archivo, por ejemplo:
--
--      sql/db/08_helpdesk_sync.sql
--
--   No se incluye aquí para no mezclar facts del dominio con integración.
-- =====================================================


-- =====================================================
-- INTEGRIDAD ADICIONAL PARA TIPO REQUERIMIENTO / ÁREA
-- =====================================================
-- Objetivo:
--   Permitir validar que cuando un ticket tenga id_area_destino e id_tipo_req,
--   ambos pertenezcan a la misma combinación definida en
--   helpdesk.dim_tipo_requerimiento.
--
-- Requiere que 05_helpdesk_dimensions.sql ya haya creado:
--   helpdesk.dim_tipo_requerimiento
-- =====================================================

CREATE UNIQUE INDEX uq_dim_tipo_requerimiento_id_tipo_req_id_area
ON helpdesk.dim_tipo_requerimiento (
    id_tipo_req,
    id_area
);


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
    -- Pueden estar NULL al momento de creación si el ticket aún no fue
    -- redirigido/asignado.
    id_area_destino UUID REFERENCES core.dim_area(id_area),
    id_asignado UUID REFERENCES core.dim_personal(id_personal),

    -- Encargado operativo interno resuelto por reglas de enrutamiento.
    --
    -- Importante:
    --   Este campo NO reemplaza id_area_destino.
    --   id_area_destino sigue siendo el área compatible con PowerApps.
    --
    -- Ejemplo:
    --   Área legacy: ADMINISTRACIÓN
    --   Tipo: proyectos y ti
    --   Categoría 1: ti
    --   encargado_interno: correo/responsable definido por routing_rule
    encargado_interno TEXT,

    -- Clasificación funcional.
    id_estado UUID NOT NULL REFERENCES helpdesk.dim_estado(id_estado),
    id_prioridad UUID REFERENCES helpdesk.dim_prioridad(id_prioridad),
    id_tipo_req UUID REFERENCES helpdesk.dim_tipo_requerimiento(id_tipo_req),

    -- Tiempos.
    -- fecha_creacion: momento real en que el ticket entra a PostgreSQL
    --                 o se migra desde legacy.
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
    -- SISTEMA_INTERNO:
    --   Ticket creado por un proceso interno no cliente.
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
    CONSTRAINT chk_fact_ticket_origen_sistema
    CHECK (
        origen_sistema IN (
            'SHAREPOINT_LEGACY',
            'PORTAL_CLIENTE',
            'SISTEMA_INTERNO'
        )
    ),

    -- Si el ticket ya tiene área destino y tipo de requerimiento,
    -- ambos deben ser coherentes con la combinación definida en
    -- helpdesk.dim_tipo_requerimiento.
    --
    -- Como id_area_destino e id_tipo_req pueden ser NULL durante creación
    -- inicial, PostgreSQL no fuerza esta FK hasta que ambos existan.
    CONSTRAINT fk_fact_ticket_tipo_req_area
    FOREIGN KEY (
        id_tipo_req,
        id_area_destino
    )
    REFERENCES helpdesk.dim_tipo_requerimiento (
        id_tipo_req,
        id_area
    )
);


-- =====================================================
-- ÍNDICES / FACT TICKET
-- =====================================================

CREATE INDEX ix_fact_ticket_cliente
ON helpdesk.fact_ticket(id_cliente_contai);

CREATE INDEX ix_fact_ticket_solicitante
ON helpdesk.fact_ticket(id_solicitante);

CREATE INDEX ix_fact_ticket_area_destino
ON helpdesk.fact_ticket(id_area_destino);

CREATE INDEX ix_fact_ticket_asignado
ON helpdesk.fact_ticket(id_asignado);

CREATE INDEX ix_fact_ticket_estado
ON helpdesk.fact_ticket(id_estado);

CREATE INDEX ix_fact_ticket_prioridad
ON helpdesk.fact_ticket(id_prioridad);

CREATE INDEX ix_fact_ticket_tipo_req
ON helpdesk.fact_ticket(id_tipo_req);

CREATE INDEX ix_fact_ticket_origen_sistema
ON helpdesk.fact_ticket(origen_sistema);

CREATE INDEX ix_fact_ticket_fecha_creacion
ON helpdesk.fact_ticket(fecha_creacion);

CREATE INDEX ix_fact_ticket_portal_pendiente_redireccion
ON helpdesk.fact_ticket(origen_sistema, id_area_destino, fecha_creacion)
WHERE origen_sistema = 'PORTAL_CLIENTE'
  AND id_area_destino IS NULL;


-- =====================================================
-- HELPDESK / EVENTOS DEL TICKET
-- =====================================================

CREATE TABLE helpdesk.fact_ticket_evento (
    id_evento UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- ID original de evento/comentario en SharePoint, si algún día se extraen
    -- eventos reales desde una lista/histórico con ID propio.
    sp_event_id INTEGER UNIQUE,

    -- Llave determinística para eventos inferidos desde columnas del ticket.
    --
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
            'CREACION',
            'COMENTARIO',
            'REASIGNACION',
            'CAMBIO_ESTADO',
            'CANCELACION_CLIENTE',
            'MIGRACION_LEGACY'
        )
    )
);


-- =====================================================
-- ÍNDICES / FACT TICKET EVENTO
-- =====================================================

CREATE INDEX ix_fact_ticket_evento_ticket
ON helpdesk.fact_ticket_evento(id_ticket);

CREATE INDEX ix_fact_ticket_evento_autor
ON helpdesk.fact_ticket_evento(id_autor);

CREATE INDEX ix_fact_ticket_evento_tipo
ON helpdesk.fact_ticket_evento(tipo_evento);

CREATE INDEX ix_fact_ticket_evento_fecha
ON helpdesk.fact_ticket_evento(fecha_registro);


-- =====================================================
-- HELPDESK / REFERENCIA LEGACY SHAREPOINT
--
-- Tabla puente temporal entre PostgreSQL canónico y SharePoint.
--
-- Guarda:
--   - sp_id: ID interno del ítem en SharePoint.
--   - legacy_id_req: Id_Req viejo generado por PowerApps.
--   - legacy_title: Title de SharePoint, que actualmente corresponde al correo.
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
    --
    -- Para tickets creados desde el portal, esta fila se crea después de que
    -- n8n/SharePoint devuelva el ID del ítem en HelpDeskBd.
    sp_id INTEGER NOT NULL UNIQUE,

    -- Id_Req legacy de PowerApps.
    -- No es UNIQUE porque ya existe al menos un duplicado en legacy.
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


-- =====================================================
-- ÍNDICES / REFERENCIA LEGACY SHAREPOINT
-- =====================================================

CREATE INDEX ix_ticket_legacy_sharepoint_ref_legacy_id_req
ON helpdesk.ticket_legacy_sharepoint_ref(legacy_id_req);

CREATE INDEX ix_ticket_legacy_sharepoint_ref_legacy_created_at
ON helpdesk.ticket_legacy_sharepoint_ref(legacy_created_at);


-- =====================================================
-- HELPDESK / ROUTING RULE
--
-- Reglas explícitas para resolver encargado interno por tipo/categoría.
--
-- Esta tabla NO crea nuevas áreas.
--
-- Caso objetivo:
--   Área legacy / PowerApps:
--      ADMINISTRACIÓN
--
--   Tipo requerimiento:
--      proyectos y ti
--
--   Categoría 1:
--      automatizacion / ti
--
--   Encargado interno:
--      se resuelve desde helpdesk.routing_rule según id_tipo_req.
--
-- Por qué NO se guarda id_area_legacy aquí:
--   id_area_legacy ya está implícita en:
--
--      helpdesk.dim_tipo_requerimiento.id_area
--
--   Duplicar ese dato permitiría inconsistencias. La regla debe depender de la
--   combinación canónica id_tipo_req, que ya incluye área, tipo, categoría 1
--   y categoría 2.
-- =====================================================

CREATE TABLE helpdesk.routing_rule (
    id_routing_rule UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Combinación exacta de:
    --   área + tipo_requerimiento + categoría_1 + categoría_2
    --
    -- La relación con área legacy se deriva desde dim_tipo_requerimiento.id_area.
    id_tipo_req UUID NOT NULL
        REFERENCES helpdesk.dim_tipo_requerimiento(id_tipo_req)
        ON DELETE CASCADE,

    -- Encargado interno operativo.
    --
    -- Puede ser:
    --   - correo del encargado interno;
    --   - alias funcional;
    --   - identificador que luego n8n/PowerApps interprete.
    --
    -- No se fuerza formato de email porque podrían usarse alias o cuentas
    -- funcionales.
    encargado_interno TEXT NOT NULL,

    descripcion TEXT,

    activo BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_routing_rule_tipo_req
    UNIQUE (id_tipo_req)
);


-- =====================================================
-- ÍNDICES / ROUTING RULE
-- =====================================================

CREATE INDEX ix_routing_rule_tipo_req
ON helpdesk.routing_rule(id_tipo_req);

CREATE INDEX ix_routing_rule_activo
ON helpdesk.routing_rule(activo);