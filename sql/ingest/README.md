# Ingesta SharePoint -> Staging

La ingesta raw desde SharePoint se ejecuta desde n8n.

Cada lista SharePoint se guarda en una tabla staging con esta estructura:

- sp_id
- payload JSONB
- extracted_at

## Query SQL base

Ver `00_upsert_staging_template.sql`.

## Query Parameters en n8n

```js
{{ [ $json.Id || $json.ID, JSON.stringify($json) ] }}