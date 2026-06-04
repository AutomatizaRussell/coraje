-- =====================================================
-- 4. HELPDESK / DIMENSIONES
-- =====================================================
CREATE TABLE helpdesk.dim_estado (
    id_estado UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre_estado VARCHAR(50) UNIQUE NOT NULL
);


CREATE TABLE helpdesk.dim_prioridad (
    id_prioridad UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    nombre_prioridad VARCHAR(50) UNIQUE NOT NULL,
    dias_sla INTEGER NOT NULL,
    peso_prioridad INTEGER NOT NULL,

    CONSTRAINT chk_dim_prioridad_dias_sla
    CHECK (dias_sla > 0),

    CONSTRAINT chk_dim_prioridad_peso
    CHECK (peso_prioridad >= 1)
);


CREATE TABLE helpdesk.dim_tipo_requerimiento (
    id_tipo_req UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- ID original de SharePoint TipoReqHD
    sp_tipo_req_id INTEGER UNIQUE,

    -- Área funcional asociada al tipo de requerimiento
    id_area UUID NOT NULL REFERENCES core.dim_area(id_area),

    tipo_requerimiento VARCHAR(150) NOT NULL,
        
    categoria_1 VARCHAR(150),
    categoria_2 VARCHAR(150),


    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_dim_tipo_req_natural
    UNIQUE (
        id_area,
        tipo_requerimiento,
        categoria_1,
        categoria_2
    )
);