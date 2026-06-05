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


-- =====================================================
-- CORE / CALENDARIO HÁBIL COLOMBIA
-- =====================================================
-- Objetivo:
--   Calcular días hábiles en Colombia sin listas fijas por año.
--
-- Reglas:
--   - Excluye sábados y domingos.
--   - Excluye festivos fijos nacionales.
--   - Excluye Jueves Santo y Viernes Santo.
--   - Excluye festivos trasladados al lunes por Ley Emiliani.
--   - El día inicial cuenta como día 0.
--
-- Uso:
--   SELECT core.add_colombia_business_days(CURRENT_DATE, 3);
-- =====================================================

CREATE OR REPLACE FUNCTION core.easter_date(p_year INTEGER)
RETURNS DATE
LANGUAGE plpgsql
IMMUTABLE
AS $fn$
DECLARE
    a INTEGER;
    b INTEGER;
    c INTEGER;
    d INTEGER;
    e INTEGER;
    f INTEGER;
    g INTEGER;
    h INTEGER;
    i INTEGER;
    k INTEGER;
    l INTEGER;
    m INTEGER;
    v_month INTEGER;
    v_day INTEGER;
BEGIN
    -- Algoritmo gregoriano de Meeus/Jones/Butcher.
    -- Calcula el Domingo de Pascua para el año recibido.
    a := p_year % 19;
    b := p_year / 100;
    c := p_year % 100;
    d := b / 4;
    e := b % 4;
    f := (b + 8) / 25;
    g := (b - f + 1) / 3;
    h := (19 * a + b - d - g + 15) % 30;
    i := c / 4;
    k := c % 4;
    l := (32 + 2 * e + 2 * i - h - k) % 7;
    m := (a + 11 * h + 22 * l) / 451;

    v_month := (h + l - 7 * m + 114) / 31;
    v_day := ((h + l - 7 * m + 114) % 31) + 1;

    RETURN make_date(p_year, v_month, v_day);
END;
$fn$;


CREATE OR REPLACE FUNCTION core.next_monday(p_date DATE)
RETURNS DATE
LANGUAGE sql
IMMUTABLE
AS $fn$
    SELECT p_date + (((8 - EXTRACT(ISODOW FROM p_date)::INTEGER) % 7))::INTEGER;
$fn$;


CREATE OR REPLACE FUNCTION core.is_colombia_holiday(p_date DATE)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $fn$
    WITH params AS (
        SELECT
            EXTRACT(YEAR FROM p_date)::INTEGER AS y,
            core.easter_date(EXTRACT(YEAR FROM p_date)::INTEGER) AS easter
    ),
    holidays AS (
        -- Festivos fijos no trasladables.
        SELECT make_date(y, 1, 1) AS holiday FROM params       -- Año Nuevo
        UNION SELECT make_date(y, 5, 1) FROM params            -- Día del Trabajo
        UNION SELECT make_date(y, 7, 20) FROM params           -- Independencia
        UNION SELECT make_date(y, 8, 7) FROM params            -- Batalla de Boyacá
        UNION SELECT make_date(y, 12, 8) FROM params           -- Inmaculada Concepción
        UNION SELECT make_date(y, 12, 25) FROM params          -- Navidad

        -- Semana Santa. No se trasladan.
        UNION SELECT easter - 3 FROM params                    -- Jueves Santo
        UNION SELECT easter - 2 FROM params                    -- Viernes Santo

        -- Festivos trasladables al lunes por Ley Emiliani.
        UNION SELECT core.next_monday(make_date(y, 1, 6)) FROM params     -- Reyes Magos
        UNION SELECT core.next_monday(make_date(y, 3, 19)) FROM params    -- San José
        UNION SELECT core.next_monday(make_date(y, 6, 29)) FROM params    -- San Pedro y San Pablo
        UNION SELECT core.next_monday(make_date(y, 8, 15)) FROM params    -- Asunción de la Virgen
        UNION SELECT core.next_monday(make_date(y, 10, 12)) FROM params   -- Día de la Raza
        UNION SELECT core.next_monday(make_date(y, 11, 1)) FROM params    -- Todos los Santos
        UNION SELECT core.next_monday(make_date(y, 11, 11)) FROM params   -- Independencia de Cartagena

        -- Festivos religiosos basados en Pascua y trasladados.
        UNION SELECT core.next_monday(easter + 39) FROM params -- Ascensión
        UNION SELECT core.next_monday(easter + 60) FROM params -- Corpus Christi
        UNION SELECT core.next_monday(easter + 68) FROM params -- Sagrado Corazón
    )
    SELECT EXISTS (
        SELECT 1
        FROM holidays
        WHERE holiday = p_date
    );
$fn$;


CREATE OR REPLACE FUNCTION core.is_colombia_business_day(p_date DATE)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $fn$
    SELECT
        EXTRACT(ISODOW FROM p_date)::INTEGER BETWEEN 1 AND 5
        AND NOT core.is_colombia_holiday(p_date);
$fn$;


CREATE OR REPLACE FUNCTION core.add_colombia_business_days(
    p_start_date DATE,
    p_days INTEGER
)
RETURNS DATE
LANGUAGE plpgsql
STABLE
AS $fn$
DECLARE
    v_date DATE := p_start_date;
    v_added INTEGER := 0;
BEGIN
    IF p_days < 0 THEN
        RAISE EXCEPTION 'p_days debe ser mayor o igual a cero. Valor recibido: %', p_days;
    END IF;

    -- Día inicial = día 0.
    -- Por eso primero avanzamos un día y luego evaluamos si ese nuevo día es hábil.
    WHILE v_added < p_days LOOP
        v_date := v_date + 1;

        IF core.is_colombia_business_day(v_date) THEN
            v_added := v_added + 1;
        END IF;
    END LOOP;

    RETURN v_date;
END;
$fn$;