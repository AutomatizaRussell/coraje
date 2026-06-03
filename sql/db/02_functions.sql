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