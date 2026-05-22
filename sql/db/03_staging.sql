
-- =====================================================
-- 2. STAGING / DATOS CRUDOS DESDE SHAREPOINT
-- =====================================================

-- Lista principal: HelpDeskBd
CREATE TABLE staging.sp_helpdesk_raw (
    sp_id INTEGER PRIMARY KEY,
    payload JSONB NOT NULL,
    extracted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Lista auxiliar: Personal GCT
CREATE TABLE staging.sp_personal_gct_raw (
    sp_id INTEGER PRIMARY KEY,
    payload JSONB NOT NULL,
    extracted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Lista auxiliar: Clientes Contai
CREATE TABLE staging.sp_clientes_contai_raw (
    sp_id INTEGER PRIMARY KEY,
    payload JSONB NOT NULL,
    extracted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Lista auxiliar: TipoReqHD
CREATE TABLE staging.sp_tipo_req_hd_raw (
    sp_id INTEGER PRIMARY KEY,
    payload JSONB NOT NULL,
    extracted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Lista auxiliar: RecibeHelpdesk
CREATE TABLE staging.sp_recibe_helpdesk_raw (
    sp_id INTEGER PRIMARY KEY,
    payload JSONB NOT NULL,
    extracted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Lista auxiliar: Días_Habiles
CREATE TABLE staging.sp_dias_habiles_raw (
    sp_id INTEGER PRIMARY KEY,
    payload JSONB NOT NULL,
    extracted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);