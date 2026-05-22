-- =====================================================
-- 8. CATÁLOGOS MÍNIMOS
-- =====================================================
INSERT INTO helpdesk.dim_estado (nombre_estado)
VALUES
    ('ABIERTO'),
    ('CERRADO'),
    ('RECHAZADO')
ON CONFLICT (nombre_estado) DO NOTHING;


INSERT INTO helpdesk.dim_prioridad (
    nombre_prioridad,
    dias_sla,
    peso_prioridad
)
VALUES
    ('BAJA', 5, 1),
    ('MEDIA', 3, 2)
ON CONFLICT (nombre_prioridad) DO NOTHING;