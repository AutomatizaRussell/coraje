-- =====================================================
-- 5. HELPDESK / SECUENCIA Y FUNCIÓN DE CÓDIGO TICKET
-- =====================================================
-- Genera códigos visibles y operativos para tickets.
-- Este código reemplaza funcionalmente al Id_Req legacy.
--
-- Ejemplo:
--   HD-2026-000001
--   HD-2026-000002
--
-- id_ticket sigue siendo la PK técnica.
-- codigo_ticket es el identificador humano/operativo.
-- =====================================================

CREATE SEQUENCE IF NOT EXISTS helpdesk.ticket_codigo_seq;

CREATE OR REPLACE FUNCTION helpdesk.next_codigo_ticket()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_num BIGINT;
BEGIN
    v_num := nextval('helpdesk.ticket_codigo_seq');

    RETURN
        'HD-'
        || EXTRACT(YEAR FROM CURRENT_DATE)::INT
        || '-'
        || LPAD(v_num::TEXT, 6, '0');
END;
$$;

-- =====================================================
-- CORE / NORMALIZACIÓN DE TEXTO
-- =====================================================
-- Objetivo:
--   Normalizar textos legacy de SharePoint para comparaciones robustas.
--
-- Normalizaciones aplicadas:
--   1. Convierte NULL o texto vacío a NULL.
--   2. Elimina tildes/acentos mediante unaccent.
--   3. Convierte a minúsculas.
--   4. Reemplaza caracteres no alfanuméricos por espacios.
--   5. Colapsa múltiples espacios consecutivos en uno solo.
--   6. Elimina espacios al inicio y al final.
--   7. Devuelve NULL si el resultado final queda vacío.
--
-- Advertencia:
--   Esta función es para matching funcional, no para conservar valores originales.
--   No debe usarse para mostrar datos al usuario ni para almacenar nombres finales.
-- =====================================================

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;

CREATE OR REPLACE FUNCTION core.norm_text(input_text TEXT)
RETURNS TEXT
LANGUAGE sql
STABLE
AS $$
    SELECT NULLIF(
        BTRIM(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    LOWER(public.unaccent(COALESCE(input_text, ''))),
                    '[^a-z0-9]+',
                    ' ',
                    'g'
                ),
                '\s+',
                ' ',
                'g'
            )
        ),
        ''
    );
$$;
