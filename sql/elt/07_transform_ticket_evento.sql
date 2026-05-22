-- =================================================================
-- EVENTOS INFERIDOS DESDE COLUMNAS LEGACY DEL TICKET
-- =================================================================
-- Estos eventos no vienen como registros independientes desde SharePoint.
-- Se derivan de columnas de HelpDeskBd.
--
-- event_hash evita duplicados si el transform se ejecuta varias veces.
-- Identidad lógica:
--   ticket SharePoint + tipo de evento inferido + contenido normalizado
-- =================================================================


-- 1. Inserción de Justificaciones de Prioridad
INSERT INTO helpdesk.fact_ticket_evento (
    event_hash,
    id_ticket,
    tipo_evento,
    contenido,
    fecha_registro
)
SELECT
    md5(
        f.consecutivo_sp::text
        || '|JUSTIFICACION_PRIORIDAD|'
        || TRIM(s.payload->>'Justifique_Prioridad')
    ) AS event_hash,

    f.id_ticket,
    'COMENTARIO' AS tipo_evento,
    'JUSTIFICACIÓN PRIORIDAD: ' || TRIM(s.payload->>'Justifique_Prioridad') AS contenido,

    COALESCE(
        NULLIF(TRIM(s.payload->>'Modified'), '')::TIMESTAMPTZ,
        NOW()
    ) AS fecha_registro

FROM staging.sp_helpdesk_raw s
JOIN helpdesk.fact_ticket f
    ON f.consecutivo_sp = s.sp_id
WHERE NULLIF(TRIM(s.payload->>'Justifique_Prioridad'), '') IS NOT NULL
ON CONFLICT (event_hash)
DO UPDATE SET
    contenido = EXCLUDED.contenido,
    fecha_registro = EXCLUDED.fecha_registro;


-- 2. Inserción de Comentarios Adicionales
INSERT INTO helpdesk.fact_ticket_evento (
    event_hash,
    id_ticket,
    tipo_evento,
    contenido,
    fecha_registro
)
SELECT
    md5(
        f.consecutivo_sp::text
        || '|COMENTARIO_ADICIONAL|'
        || TRIM(s.payload->>'Comentarios_adicionales')
    ) AS event_hash,

    f.id_ticket,
    'COMENTARIO' AS tipo_evento,
    'COMENTARIO ADICIONAL: ' || TRIM(s.payload->>'Comentarios_adicionales') AS contenido,

    COALESCE(
        NULLIF(TRIM(s.payload->>'Modified'), '')::TIMESTAMPTZ,
        NOW()
    ) AS fecha_registro

FROM staging.sp_helpdesk_raw s
JOIN helpdesk.fact_ticket f
    ON f.consecutivo_sp = s.sp_id
WHERE NULLIF(TRIM(s.payload->>'Comentarios_adicionales'), '') IS NOT NULL
ON CONFLICT (event_hash)
DO UPDATE SET
    contenido = EXCLUDED.contenido,
    fecha_registro = EXCLUDED.fecha_registro;


-- 3. Inserción de Observaciones
INSERT INTO helpdesk.fact_ticket_evento (
    event_hash,
    id_ticket,
    tipo_evento,
    contenido,
    fecha_registro
)
SELECT
    md5(
        f.consecutivo_sp::text
        || '|OBSERVACION|'
        || TRIM(s.payload->>'Observaci_x00f3_n')
    ) AS event_hash,

    f.id_ticket,
    'COMENTARIO' AS tipo_evento,
    'OBSERVACIÓN: ' || TRIM(s.payload->>'Observaci_x00f3_n') AS contenido,

    COALESCE(
        NULLIF(TRIM(s.payload->>'Modified'), '')::TIMESTAMPTZ,
        NOW()
    ) AS fecha_registro

FROM staging.sp_helpdesk_raw s
JOIN helpdesk.fact_ticket f
    ON f.consecutivo_sp = s.sp_id
WHERE NULLIF(TRIM(s.payload->>'Observaci_x00f3_n'), '') IS NOT NULL
ON CONFLICT (event_hash)
DO UPDATE SET
    contenido = EXCLUDED.contenido,
    fecha_registro = EXCLUDED.fecha_registro;


-- 4. Inserción de Respuestas Sugeridas
INSERT INTO helpdesk.fact_ticket_evento (
    event_hash,
    id_ticket,
    tipo_evento,
    contenido,
    fecha_registro
)
SELECT
    md5(
        f.consecutivo_sp::text
        || '|RESPUESTA_SUGERIDA|'
        || TRIM(s.payload->>'Respuesta_Sugerida')
    ) AS event_hash,

    f.id_ticket,
    'COMENTARIO' AS tipo_evento,
    'RESPUESTA SUGERIDA: ' || TRIM(s.payload->>'Respuesta_Sugerida') AS contenido,

    COALESCE(
        NULLIF(TRIM(s.payload->>'Modified'), '')::TIMESTAMPTZ,
        NOW()
    ) AS fecha_registro

FROM staging.sp_helpdesk_raw s
JOIN helpdesk.fact_ticket f
    ON f.consecutivo_sp = s.sp_id
WHERE NULLIF(TRIM(s.payload->>'Respuesta_Sugerida'), '') IS NOT NULL
ON CONFLICT (event_hash)
DO UPDATE SET
    contenido = EXCLUDED.contenido,
    fecha_registro = EXCLUDED.fecha_registro;
