-- =================================================================
-- RECUPERACIÓN DE EMPLEADOS HISTÓRICOS DESDE LOS TICKETS (INFERIDOS)
-- =================================================================
INSERT INTO core.dim_personal (
    nombre_completo,
    correo_corporativo,
    cargo,
    estado_activo
)
SELECT 
    UPPER(SPLIT_PART(correo_fantasma, '@', 1)) AS nombre_completo,
    correo_fantasma AS correo_corporativo,
    'EX-EMPLEADO (RECUPERADO DEL HISTORIAL)' AS cargo,
    FALSE AS estado_activo
FROM (
    -- Extraemos todos los correos únicos de los Solicitantes y Asignados en los tickets
    SELECT TRIM(LOWER(payload->>'Title')) AS correo_fantasma FROM staging.sp_helpdesk_raw
    UNION
    SELECT TRIM(LOWER(payload->>'AsignadoA')) FROM staging.sp_helpdesk_raw
) lista_correos
WHERE correo_fantasma IS NOT NULL 
  AND correo_fantasma LIKE '%@%.%' -- Validación básica de que sí es un correo
  -- El filtro mágico: Solo inserta los que NO existan ya en tu dimensión de personal
  AND correo_fantasma NOT IN (
      SELECT correo_corporativo 
      FROM core.dim_personal 
      WHERE correo_corporativo IS NOT NULL
  );