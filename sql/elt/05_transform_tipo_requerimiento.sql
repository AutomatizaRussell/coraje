-- ============================================================
-- Transformación: TipoReqHD -> helpdesk.dim_tipo_requerimiento
-- ============================================================
-- Relación real desde SharePoint:
--   TipoReqHD.Title              -> core.dim_area.nombre_area
--   TipoReqHD.Tipo_Requerimiento -> tipo_requerimiento
--   TipoReqHD.Categor_x00ed_a1   -> categoria_1
--   TipoReqHD.Categor_x00ed_a2   -> categoria_2
--
-- Nota:
--   SharePoint codifica columnas con tilde.
--   "Categoría1" aparece en JSON como "Categor_x00ed_a1".
--   "Categoría2" aparece en JSON como "Categor_x00ed_a2".
-- ============================================================

INSERT INTO helpdesk.dim_tipo_requerimiento (
    sp_tipo_req_id,
    id_area,
    tipo_requerimiento,
    categoria_1,
    categoria_2
)
SELECT DISTINCT ON (
    a.id_area,
    core.norm_text(s.payload->>'Tipo_Requerimiento'),
    core.norm_text(s.payload->>'Categor_x00ed_a1'),
    core.norm_text(s.payload->>'Categor_x00ed_a2')
)
    s.sp_id AS sp_tipo_req_id,
    a.id_area,
    core.norm_text(s.payload->>'Tipo_Requerimiento') AS tipo_requerimiento,
    core.norm_text(s.payload->>'Categor_x00ed_a1') AS categoria_1,
    core.norm_text(s.payload->>'Categor_x00ed_a2') AS categoria_2
FROM staging.sp_tipo_req_hd_raw s
JOIN core.dim_area a
    ON core.norm_text(s.payload->>'Title') = core.norm_text(a.nombre_area)
WHERE core.norm_text(s.payload->>'Title') IS NOT NULL
  AND core.norm_text(s.payload->>'Tipo_Requerimiento') IS NOT NULL
ORDER BY
    a.id_area,
    core.norm_text(s.payload->>'Tipo_Requerimiento'),
    core.norm_text(s.payload->>'Categor_x00ed_a1') NULLS FIRST,
    core.norm_text(s.payload->>'Categor_x00ed_a2') NULLS FIRST,
    s.sp_id
ON CONFLICT ON CONSTRAINT uq_dim_tipo_req_natural
DO UPDATE SET
    sp_tipo_req_id = LEAST(
        helpdesk.dim_tipo_requerimiento.sp_tipo_req_id,
        EXCLUDED.sp_tipo_req_id
    ),
    updated_at = NOW();
