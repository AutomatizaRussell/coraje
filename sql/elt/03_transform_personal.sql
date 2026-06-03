    -- ================================================
    -- TRANSFORMACIÓN DE LA TABLA DE PERSONAL
    -- ================================================
    INSERT INTO core.dim_personal (
        sp_personal_id, 
        cedula, 
        nombre_completo, 
        correo_corporativo, 
        id_area, 
        cargo, 
        estado_activo
    )
    SELECT 
        MIN(s.sp_id) AS sp_personal_id,
        TRIM(s.payload->>'Title') AS cedula,
        
        TRIM(UPPER(COALESCE(
            s.payload->>'DISPLAYNAME', 
            s.payload->>'field_1', 
            s.payload->>'Foto'
        ))) AS nombre_completo,
        
        TRIM(LOWER(s.payload->>'field_2')) AS correo_corporativo,
        a.id_area, 
        TRIM(UPPER(s.payload->>'CARGO')) AS cargo,
        CASE 
            WHEN TRIM(UPPER(s.payload->>'Estado')) = 'ACTIVO' THEN TRUE 
            ELSE FALSE 
        END AS estado_activo
    FROM staging.sp_personal_gct_raw s

    -- EL PUENTE ANTI-TILDES: Quitamos las vocales con tilde de ambos lados solo para comparar
    LEFT JOIN core.dim_area a 
        ON TRANSLATE(TRIM(UPPER(s.payload->>'field_3')), 'ÁÉÍÓÚ', 'AEIOU') = TRANSLATE(a.nombre_area, 'ÁÉÍÓÚ', 'AEIOU')

    WHERE COALESCE(s.payload->>'DISPLAYNAME', s.payload->>'field_1') IS NOT NULL
    GROUP BY 
        TRIM(s.payload->>'Title'),
        TRIM(UPPER(COALESCE(s.payload->>'DISPLAYNAME', s.payload->>'field_1', s.payload->>'Foto'))),
        TRIM(LOWER(s.payload->>'field_2')),
        a.id_area,
        TRIM(UPPER(s.payload->>'CARGO')),
        CASE WHEN TRIM(UPPER(s.payload->>'Estado')) = 'ACTIVO' THEN TRUE ELSE FALSE END
    ON CONFLICT (sp_personal_id) 
    DO UPDATE SET 
        cedula = EXCLUDED.cedula,
        nombre_completo = EXCLUDED.nombre_completo,
        correo_corporativo = EXCLUDED.correo_corporativo,
        id_area = EXCLUDED.id_area,
        cargo = EXCLUDED.cargo,
        estado_activo = EXCLUDED.estado_activo,
        updated_at = NOW();