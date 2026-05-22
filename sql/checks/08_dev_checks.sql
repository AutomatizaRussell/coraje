SELECT COUNT(*) AS total_tickets
FROM helpdesk.fact_ticket;

SELECT COUNT(*) AS total_eventos
FROM helpdesk.fact_ticket_evento;

SELECT COUNT(*) AS tickets_sin_area
FROM helpdesk.fact_ticket
WHERE id_area_destino IS NULL;

SELECT COUNT(*) AS tickets_sin_tipo_req
FROM helpdesk.fact_ticket
WHERE id_tipo_req IS NULL;

SELECT COUNT(*) AS tickets_sin_prioridad
FROM helpdesk.fact_ticket
WHERE id_prioridad IS NULL;

SELECT
    COUNT(*) AS total_eventos,
    COUNT(DISTINCT event_hash) AS eventos_unicos
FROM helpdesk.fact_ticket_evento
WHERE event_hash IS NOT NULL;


SELECT
    f.consecutivo_sp,
    s.payload->>'Id_Req' AS id_req,
    core.norm_text(s.payload->>'OData__x00c1_rea_Destino') AS area_destino,
    core.norm_text(s.payload->>'Tipo_Requerimiento') AS tipo_requerimiento,
    core.norm_text(s.payload->>'Categor_x00ed_a1') AS categoria_1,
    core.norm_text(s.payload->>'Categor_x00ed_a2') AS categoria_2
FROM helpdesk.fact_ticket f
JOIN staging.sp_helpdesk_raw s
    ON s.sp_id = f.consecutivo_sp
WHERE f.id_tipo_req IS NULL
ORDER BY f.consecutivo_sp;
