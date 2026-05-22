-- Transformación de la tabla de clientes contai
INSERT INTO core.dim_cliente_contai (
    sp_cliente_id, 
    identificacion_fiscal, 
    nombre_cliente, 
    tipo_cliente, 
    grupo_economico, 
    estado_cliente
)
SELECT 
    MIN(sp_id) AS sp_cliente_id,
    TRIM(payload->>'Title') AS identificacion_fiscal,
    TRIM(UPPER(payload->>'Cliente')) AS nombre_cliente,
    TRIM(UPPER(payload->>'TIPOCLIENTE')) AS tipo_cliente,
    TRIM(UPPER(payload->>'Grupoecon_x00f3_mico')) AS grupo_economico,
    CASE 
        WHEN TRIM(UPPER(payload->>'Estado')) = 'ACTIVO' THEN TRUE 
        ELSE FALSE 
    END AS estado_cliente
FROM staging.sp_clientes_contai_raw
WHERE payload->>'Cliente' IS NOT NULL
GROUP BY 
    TRIM(payload->>'Title'),
    TRIM(UPPER(payload->>'Cliente')),
    TRIM(UPPER(payload->>'TIPOCLIENTE')),
    TRIM(UPPER(payload->>'Grupoecon_x00f3_mico')),
    CASE WHEN TRIM(UPPER(payload->>'Estado')) = 'ACTIVO' THEN TRUE ELSE FALSE END
ON CONFLICT (sp_cliente_id) 
DO UPDATE SET 
    identificacion_fiscal = EXCLUDED.identificacion_fiscal,
    nombre_cliente = EXCLUDED.nombre_cliente,
    tipo_cliente = EXCLUDED.tipo_cliente,
    grupo_economico = EXCLUDED.grupo_economico,
    estado_cliente = EXCLUDED.estado_cliente,
    updated_at = NOW();

    
-- TODO producción:
-- evaluar UNIQUE parcial por identificacion_fiscal.
