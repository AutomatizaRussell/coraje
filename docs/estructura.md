/sql
  /db
    00_extensions.sql
    01_schemas.sql
    02_functions.sql
    03_staging.sql
    04_core.sql
    05_helpdesk_dimensions.sql
    06_helpdesk_facts.sql
    07_seed.sql

  /ingest
    00_upsert_staging_template.sql
    README.md

  /elt
    01_transform_area.sql
    02_transform_clientes.sql
    03_transform_personal.sql
    04_transform_personal_historico.sql
    05_transform_tipo_requerimiento.sql
    06_transform_ticket.sql
    07_transform_ticket_evento.sql

  /checks
    08_dev_checks.sql

/n8n
  /workflows
    sharepoint_to_staging_helpdesk.json
    sharepoint_to_staging_auxiliares.json
  README.md

/docs
  arquitectura_actual.md
  hallazgos_migracion.md
  reglas_legacy.md
  baseline_calidad.md
  estrategia_transicion.md
  decisiones_tecnicas.md