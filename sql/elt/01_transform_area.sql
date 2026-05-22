-- Transformación de la tabla de areas
INSERT INTO core.dim_area (
    sp_area_id, 
    nombre_area, 
    encargado_recepcion
)
SELECT 
    MIN(sp_id) AS sp_area_id,
    TRIM(UPPER(payload->>'Area')) AS nombre_area,
    TRIM(LOWER(payload->>'Recibe')) AS encargado_recepcion
FROM staging.sp_recibe_helpdesk_raw
WHERE payload->>'Area' IS NOT NULL 
GROUP BY 
    TRIM(UPPER(payload->>'Area')),
    TRIM(LOWER(payload->>'Recibe'))
ON CONFLICT (nombre_area) 
DO UPDATE SET 
    sp_area_id = EXCLUDED.sp_area_id,
    encargado_recepcion = EXCLUDED.encargado_recepcion,
    updated_at = NOW();