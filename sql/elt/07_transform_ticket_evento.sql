-- =================================================================
-- 07_transform_ticket_evento.sql
-- EVENTOS INFERIDOS DESDE COLUMNAS LEGACY DEL TICKET
-- =================================================================
--
-- Estos eventos no vienen como registros independientes desde SharePoint.
-- Se derivan de columnas de HelpDeskBd almacenadas en staging.sp_helpdesk_raw.
--
-- Modelo nuevo:
--   - helpdesk.fact_ticket ya NO contiene consecutivo_sp.
--   - La relación con SharePoint vive en helpdesk.ticket_legacy_sharepoint_ref.
--
-- Por tanto:
--   - staging.sp_helpdesk_raw.sp_id se une contra ticket_legacy_sharepoint_ref.sp_id.
--   - ticket_legacy_sharepoint_ref.id_ticket se une contra fact_ticket.id_ticket.
--
-- event_hash evita duplicados si el transform se ejecuta varias veces.
--
-- Identidad lógica de evento legacy:
--   SharePoint sp_id + tipo de evento inferido + contenido normalizado
-- =================================================================


-- =================================================================
-- 1. INSERCIÓN DE JUSTIFICACIONES DE PRIORIDAD
-- =================================================================

INSERT INTO helpdesk.fact_ticket_evento (
    event_hash,
    id_ticket,
    tipo_evento,
    contenido,
    fecha_registro
)
SELECT
    md5(
        ref.sp_id::TEXT
        || '|JUSTIFICACION_PRIORIDAD|'
        || TRIM(s.payload->>'Justifique_Prioridad')
    ) AS event_hash,

    f.id_ticket,

    'COMENTARIO' AS tipo_evento,

    'JUSTIFICACIÓN PRIORIDAD: '
        || TRIM(s.payload->>'Justifique_Prioridad') AS contenido,

    COALESCE(
        NULLIF(TRIM(s.payload->>'Modified'), '')::TIMESTAMPTZ,
        NOW()
    ) AS fecha_registro

FROM staging.sp_helpdesk_raw s

JOIN helpdesk.ticket_legacy_sharepoint_ref ref
    ON ref.sp_id = s.sp_id

JOIN helpdesk.fact_ticket f
    ON f.id_ticket = ref.id_ticket

WHERE
    NULLIF(TRIM(s.payload->>'Justifique_Prioridad'), '') IS NOT NULL

ON CONFLICT (event_hash)
DO UPDATE SET
    contenido = EXCLUDED.contenido,
    fecha_registro = EXCLUDED.fecha_registro;


-- =================================================================
-- 2. INSERCIÓN DE COMENTARIOS ADICIONALES
-- =================================================================

INSERT INTO helpdesk.fact_ticket_evento (
    event_hash,
    id_ticket,
    tipo_evento,
    contenido,
    fecha_registro
)
SELECT
    md5(
        ref.sp_id::TEXT
        || '|COMENTARIO_ADICIONAL|'
        || TRIM(s.payload->>'Comentarios_adicionales')
    ) AS event_hash,

    f.id_ticket,

    'COMENTARIO' AS tipo_evento,

    'COMENTARIO ADICIONAL: '
        || TRIM(s.payload->>'Comentarios_adicionales') AS contenido,

    COALESCE(
        NULLIF(TRIM(s.payload->>'Modified'), '')::TIMESTAMPTZ,
        NOW()
    ) AS fecha_registro

FROM staging.sp_helpdesk_raw s

JOIN helpdesk.ticket_legacy_sharepoint_ref ref
    ON ref.sp_id = s.sp_id

JOIN helpdesk.fact_ticket f
    ON f.id_ticket = ref.id_ticket

WHERE
    NULLIF(TRIM(s.payload->>'Comentarios_adicionales'), '') IS NOT NULL

ON CONFLICT (event_hash)
DO UPDATE SET
    contenido = EXCLUDED.contenido,
    fecha_registro = EXCLUDED.fecha_registro;


-- =================================================================
-- 3. INSERCIÓN DE OBSERVACIONES
-- =================================================================

INSERT INTO helpdesk.fact_ticket_evento (
    event_hash,
    id_ticket,
    tipo_evento,
    contenido,
    fecha_registro
)
SELECT
    md5(
        ref.sp_id::TEXT
        || '|OBSERVACION|'
        || TRIM(s.payload->>'Observaci_x00f3_n')
    ) AS event_hash,

    f.id_ticket,

    'COMENTARIO' AS tipo_evento,

    'OBSERVACIÓN: '
        || TRIM(s.payload->>'Observaci_x00f3_n') AS contenido,

    COALESCE(
        NULLIF(TRIM(s.payload->>'Modified'), '')::TIMESTAMPTZ,
        NOW()
    ) AS fecha_registro

FROM staging.sp_helpdesk_raw s

JOIN helpdesk.ticket_legacy_sharepoint_ref ref
    ON ref.sp_id = s.sp_id

JOIN helpdesk.fact_ticket f
    ON f.id_ticket = ref.id_ticket

WHERE
    NULLIF(TRIM(s.payload->>'Observaci_x00f3_n'), '') IS NOT NULL

ON CONFLICT (event_hash)
DO UPDATE SET
    contenido = EXCLUDED.contenido,
    fecha_registro = EXCLUDED.fecha_registro;


-- =================================================================
-- 4. INSERCIÓN DE RESPUESTAS SUGERIDAS
-- =================================================================

INSERT INTO helpdesk.fact_ticket_evento (
    event_hash,
    id_ticket,
    tipo_evento,
    contenido,
    fecha_registro
)
SELECT
    md5(
        ref.sp_id::TEXT
        || '|RESPUESTA_SUGERIDA|'
        || TRIM(s.payload->>'Respuesta_Sugerida')
    ) AS event_hash,

    f.id_ticket,

    'COMENTARIO' AS tipo_evento,

    'RESPUESTA SUGERIDA: '
        || TRIM(s.payload->>'Respuesta_Sugerida') AS contenido,

    COALESCE(
        NULLIF(TRIM(s.payload->>'Modified'), '')::TIMESTAMPTZ,
        NOW()
    ) AS fecha_registro

FROM staging.sp_helpdesk_raw s

JOIN helpdesk.ticket_legacy_sharepoint_ref ref
    ON ref.sp_id = s.sp_id

JOIN helpdesk.fact_ticket f
    ON f.id_ticket = ref.id_ticket

WHERE
    NULLIF(TRIM(s.payload->>'Respuesta_Sugerida'), '') IS NOT NULL

ON CONFLICT (event_hash)
DO UPDATE SET
    contenido = EXCLUDED.contenido,
    fecha_registro = EXCLUDED.fecha_registro;