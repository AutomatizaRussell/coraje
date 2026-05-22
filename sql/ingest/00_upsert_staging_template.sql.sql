-- ============================================================
-- INGESTA RAW SHAREPOINT -> STAGING
-- ============================================================
-- Uso:
--   Esta consulta se ejecuta desde un nodo PostgreSQL en n8n.
--
-- Objetivo:
--   Insertar o actualizar un ítem crudo de SharePoint en su tabla
--   staging correspondiente.
--
-- Patrón:
--   Una tabla staging por lista SharePoint.
--
-- Ejemplos de tablas destino:
--   staging.sp_helpdesk_raw
--   staging.sp_personal_gct_raw
--   staging.sp_clientes_contai_raw
--   staging.sp_tipo_req_hd_raw
--   staging.sp_recibe_helpdesk_raw
--   staging.sp_dias_habiles_raw
--
-- IMPORTANTE:
--   Reemplazar "sp_nombre_lista_raw" por la tabla real.
-- ============================================================

INSERT INTO staging.sp_nombre_lista_raw (
    sp_id,
    payload,
    extracted_at
)
VALUES (
    $1,
    $2::jsonb,
    NOW()
)
ON CONFLICT (sp_id)
DO UPDATE SET
    payload = EXCLUDED.payload,
    extracted_at = NOW();

-- ============================================================
-- n8n Query Parameters
-- ============================================================
-- Usar en el campo "Query Parameters" del nodo PostgreSQL:
--
-- {{ [ $json.Id || $json.ID, JSON.stringify($json) ] }}
--
-- Explicación:
--   $json.Id || $json.ID
--     Toma el ID del ítem de SharePoint.
--     Algunas respuestas vienen como Id y otras como ID.
--
--   JSON.stringify($json)
--     Convierte el objeto completo recibido desde SharePoint
--     en texto JSON para guardarlo como JSONB.
-- ============================================================