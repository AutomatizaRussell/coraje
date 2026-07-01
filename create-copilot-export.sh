#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Exportador saneado para proyectos de Daniel:
# Next.js / Prisma / Docker / pnpm / Node.js / TailwindCSS / PostgreSQL / n8n
# con posibles variantes NestJS, Astro y carpetas raíz que contienen docs, SQL,
# workflows JSON de n8n y uno o varios proyectos fullstack internos.
#
# Objetivo:
#   - Crear un ZIP dentro del mismo proyecto.
#   - Generar manifest exacto de archivos incluidos.
#   - Generar listado plano.
#   - Generar árbol basado en el mismo manifest.
#   - Generar reporte de warnings por posibles secretos.
#   - Excluir basura operativa, builds, caches, dependencias y secretos obvios.
#
# Uso:
#   bash create-copilot-export.sh
#   bash create-copilot-export.sh nombre-proyecto
#
# Opciones por variable de entorno:
#   FAIL_ON_WARNINGS=1 bash create-copilot-export.sh coraje
#     Falla si detecta patrones sospechosos en warnings.
#
#   MAX_FILE_MB=25 bash create-copilot-export.sh coraje
#     Excluye archivos individuales mayores a ese tamaño. Default: 25 MB.
#
# Salida:
#   .copilot-export/<nombre>-<timestamp>.sanitized.zip
#   .copilot-export/<nombre>-<timestamp>.manifest.txt
#   .copilot-export/<nombre>-<timestamp>.files.txt
#   .copilot-export/<nombre>-<timestamp>.tree.txt
#   .copilot-export/<nombre>-<timestamp>.warnings.txt
#   .copilot-export/<nombre>-<timestamp>.sha256
# ==============================================================================

PROJECT_ROOT="$(pwd)"
PROJECT_NAME="${1:-$(basename "${PROJECT_ROOT}")}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

EXPORT_DIR="${PROJECT_ROOT}/.copilot-export"
ZIP_FILE="${EXPORT_DIR}/${PROJECT_NAME}-${TIMESTAMP}.sanitized.zip"
MANIFEST_FILE="${EXPORT_DIR}/${PROJECT_NAME}-${TIMESTAMP}.manifest.txt"
FILES_FILE="${EXPORT_DIR}/${PROJECT_NAME}-${TIMESTAMP}.files.txt"
TREE_FILE="${EXPORT_DIR}/${PROJECT_NAME}-${TIMESTAMP}.tree.txt"
WARNINGS_FILE="${EXPORT_DIR}/${PROJECT_NAME}-${TIMESTAMP}.warnings.txt"
SHA_FILE="${EXPORT_DIR}/${PROJECT_NAME}-${TIMESTAMP}.sha256"

FAIL_ON_WARNINGS="${FAIL_ON_WARNINGS:-0}"
MAX_FILE_MB="${MAX_FILE_MB:-25}"
MAX_FILE_BYTES="$((MAX_FILE_MB * 1024 * 1024))"

mkdir -p "${EXPORT_DIR}"

# ------------------------------------------------------------------------------
# Validaciones de herramientas mínimas.
# ------------------------------------------------------------------------------

if ! command -v find >/dev/null 2>&1; then
  echo "ERROR: find no está disponible."
  exit 1
fi

if ! command -v zip >/dev/null 2>&1; then
  echo "ERROR: zip no está instalado."
  echo "Instala con:"
  echo "  sudo apt-get update && sudo apt-get install -y zip"
  exit 1
fi

if ! command -v sha256sum >/dev/null 2>&1; then
  echo "ERROR: sha256sum no está disponible."
  exit 1
fi

# ------------------------------------------------------------------------------
# Validación básica de ubicación.
# No obliga a que la raíz sea Next.js. Permite carpetas contenedoras como:
#   coraje/
#     docs/
#     sql/
#     n8n/
#     app-fullstack/
# ------------------------------------------------------------------------------

looks_like_project=0

if [[ -f "package.json" || -f "pnpm-lock.yaml" || -f "pnpm-workspace.yaml" ]]; then
  looks_like_project=1
fi

if [[ -d "prisma" || -d "src" || -d "app" || -d "apps" || -d "packages" ]]; then
  looks_like_project=1
fi

if find . -maxdepth 3 \( -name "package.json" -o -name "pnpm-lock.yaml" -o -name "schema.prisma" -o -name "Dockerfile" \) -print -quit | grep -q .; then
  looks_like_project=1
fi

if [[ "${looks_like_project}" -ne 1 ]]; then
  echo "ADVERTENCIA: esta carpeta no parece un proyecto de software típico."
  echo "Ruta actual: ${PROJECT_ROOT}"
  echo "Si estás en la ruta correcta, puedes continuar. Esperando 3 segundos..."
  sleep 3
fi

# ------------------------------------------------------------------------------
# Función central de exclusión.
#
# Regla de diseño:
#   - Incluir por defecto.
#   - Excluir solo lo innecesario, generado, pesado o sensible.
#
# Esto permite incluir:
#   - docs propias en Markdown/TXT;
#   - SQL de consultas y migraciones;
#   - JSON de workflows n8n;
#   - Prisma schema/migrations;
#   - Dockerfiles y compose;
#   - NestJS/Astro/Next.js;
#   - carpetas fullstack internas.
# ------------------------------------------------------------------------------

should_exclude_path() {
  local rel="$1"
  local base
  base="$(basename "$rel")"

  # Normaliza rutas sin prefijo ./.
  rel="${rel#./}"

  # --------------------------------------------------------------------------
  # 1) Nunca incluir la propia carpeta de exportación.
  # --------------------------------------------------------------------------
  case "$rel" in
    .copilot-export|.copilot-export/*)
      return 0
      ;;
  esac

  # --------------------------------------------------------------------------
  # 2) Control de versiones.
  # Se excluye .git completo porque puede contener historial, remotos y datos
  # innecesarios. El código actual queda incluido fuera de .git.
  # --------------------------------------------------------------------------
  case "$rel" in
    .git|.git/*|*/.git|*/.git/*)
      return 0
      ;;
    .gitlab|.gitlab/*|*/.gitlab|*/.gitlab/*)
      return 0
      ;;
  esac

  # Nota: .github normalmente se puede incluir porque workflows CI son código.
  # Solo se excluyen caches internas si existieran.
  case "$rel" in
    .github/cache|.github/cache/*|*/.github/cache|*/.github/cache/*)
      return 0
      ;;
  esac

  # --------------------------------------------------------------------------
  # 3) Dependencias, builds, caches y salidas generadas.
  # --------------------------------------------------------------------------
  case "$rel" in
    node_modules|node_modules/*|*/node_modules|*/node_modules/*)
      return 0
      ;;
    .next|.next/*|*/.next|*/.next/*)
      return 0
      ;;
    out|out/*|*/out|*/out/*)
      return 0
      ;;
    dist|dist/*|*/dist|*/dist/*)
      return 0
      ;;
    build|build/*|*/build|*/build/*)
      return 0
      ;;
    .turbo|.turbo/*|*/.turbo|*/.turbo/*)
      return 0
      ;;
    .vercel|.vercel/*|*/.vercel|*/.vercel/*)
      return 0
      ;;
    .netlify|.netlify/*|*/.netlify|*/.netlify/*)
      return 0
      ;;
    .output|.output/*|*/.output|*/.output/*)
      return 0
      ;;
    .astro|.astro/*|*/.astro|*/.astro/*)
      return 0
      ;;
    .cache|.cache/*|*/.cache|*/.cache/*)
      return 0
      ;;
    cache|cache/*|*/cache|*/cache/*)
      return 0
      ;;
    .parcel-cache|.parcel-cache/*|*/.parcel-cache|*/.parcel-cache/*)
      return 0
      ;;
    .vite|.vite/*|*/.vite|*/.vite/*)
      return 0
      ;;
    .swc|.swc/*|*/.swc|*/.swc/*)
      return 0
      ;;
  esac

  # pnpm/yarn caches. Se conservan package.json, pnpm-lock.yaml,
  # pnpm-workspace.yaml y configs normales.
  case "$rel" in
    .pnpm-store|.pnpm-store/*|*/.pnpm-store|*/.pnpm-store/*)
      return 0
      ;;
    .yarn/cache|.yarn/cache/*|*/.yarn/cache|*/.yarn/cache/*)
      return 0
      ;;
    .yarn/unplugged|.yarn/unplugged/*|*/.yarn/unplugged|*/.yarn/unplugged/*)
      return 0
      ;;
    .yarn/build-state.yml|*/.yarn/build-state.yml)
      return 0
      ;;
    .yarn/install-state.gz|*/.yarn/install-state.gz)
      return 0
      ;;
  esac

  # --------------------------------------------------------------------------
  # 4) Reportes de test, cobertura y artefactos generados.
  # --------------------------------------------------------------------------
  case "$rel" in
    coverage|coverage/*|*/coverage|*/coverage/*)
      return 0
      ;;
    .nyc_output|.nyc_output/*|*/.nyc_output|*/.nyc_output/*)
      return 0
      ;;
    playwright-report|playwright-report/*|*/playwright-report|*/playwright-report/*)
      return 0
      ;;
    test-results|test-results/*|*/test-results|*/test-results/*)
      return 0
      ;;
    cypress/videos|cypress/videos/*|*/cypress/videos|*/cypress/videos/*)
      return 0
      ;;
    cypress/screenshots|cypress/screenshots/*|*/cypress/screenshots|*/cypress/screenshots/*)
      return 0
      ;;
  esac

  # --------------------------------------------------------------------------
  # 5) Logs y temporales.
  # --------------------------------------------------------------------------
  case "$rel" in
    logs|logs/*|*/logs|*/logs/*)
      return 0
      ;;
    log|log/*|*/log|*/log/*)
      return 0
      ;;
    tmp|tmp/*|*/tmp|*/tmp/*)
      return 0
      ;;
    temp|temp/*|*/temp|*/temp/*)
      return 0
      ;;
    .tmp|.tmp/*|*/.tmp|*/.tmp/*)
      return 0
      ;;
  esac

  case "$base" in
    *.log|npm-debug.log*|yarn-debug.log*|yarn-error.log*|pnpm-debug.log*)
      return 0
      ;;
  esac

  # --------------------------------------------------------------------------
  # 6) IDE / SO.
  # Se excluyen configuraciones personales. Si algún proyecto necesita incluir
  # settings compartidos de VSCode, se puede ajustar explícitamente después.
  # --------------------------------------------------------------------------
  case "$rel" in
    .idea|.idea/*|*/.idea|*/.idea/*)
      return 0
      ;;
    .vscode|.vscode/*|*/.vscode|*/.vscode/*)
      return 0
      ;;
  esac

  case "$base" in
    .DS_Store|Thumbs.db|desktop.ini)
      return 0
      ;;
  esac

  # --------------------------------------------------------------------------
  # 7) Variables de entorno y archivos de secretos.
  #
  # Se excluyen .env reales.
  # Se permiten plantillas .env.example/.sample/.template, pero luego se escanean
  # en warnings porque a veces la gente mete secretos reales ahí.
  # --------------------------------------------------------------------------
  case "$base" in
    .env|.env.*)
      case "$base" in
        .env.example|.env.sample|.env.template|.env.local.example|.env.production.example|.env.development.example|.env.test.example)
          return 1
          ;;
        *)
          return 0
          ;;
      esac
      ;;
    *.env|*.env.*|.envrc)
      return 0
      ;;
  esac

  # Archivos de configuración que suelen contener tokens.
  case "$base" in
    .npmrc|.pypirc|.netrc)
      return 0
      ;;
  esac

  # Directorios convencionales de secretos.
  case "$rel" in
    secrets|secrets/*|*/secrets|*/secrets/*)
      return 0
      ;;
    private|private/*|*/private|*/private/*)
      return 0
      ;;
  esac

  # Llaves/certificados.
  case "$base" in
    *.pem|*.key|*.crt|*.cer|*.p12|*.pfx|*.jks|*.keystore)
      return 0
      ;;
    id_rsa|id_rsa.pub|id_ed25519|id_ed25519.pub)
      return 0
      ;;
  esac

  # JSON sensibles por nombre.
  # Importante: NO se excluyen todos los JSON, porque quieres incluir workflows
  # n8n y configuraciones versionadas. Solo se excluyen nombres claramente
  # peligrosos.
  case "$rel" in
    *credential*.json|*credentials*.json|*secret*.json|*secrets*.json|*token*.json|*tokens*.json|*service-account*.json|*service_account*.json)
      return 0
      ;;
    *n8n*credential*.json|*n8n*credentials*.json)
      return 0
      ;;
  esac

  # --------------------------------------------------------------------------
  # 8) SQL.
  #
  # En tu contexto SQL puede ser código: consultas, migraciones, scripts de BD.
  # Por tanto NO se excluye *.sql genéricamente.
  #
  # Pero sí se excluyen dumps/backups/base local por nombre o extensión, porque
  # pueden contener datos reales de clientes, usuarios o producción.
  # --------------------------------------------------------------------------
  case "$rel" in
    *dump*.sql|*dumps*.sql|*backup*.sql|*backups*.sql|*respaldo*.sql|*respaldos*.sql)
      return 0
      ;;
    *export*.sql|*exports*.sql)
      return 0
      ;;
    *prod*.sql|*production*.sql|*produccion*.sql)
      return 0
      ;;
    *snapshot*.sql|*snapshots*.sql)
      return 0
      ;;
  esac

  case "$base" in
    *.dump|*.bak|*.backup|*.sqlite|*.sqlite3|*.db|*.db-wal|*.db-shm|*.psql)
      return 0
      ;;
  esac

  # --------------------------------------------------------------------------
  # 9) Archivos comprimidos o paquetes previos.
  # --------------------------------------------------------------------------
  case "$base" in
    *.zip|*.tar|*.tar.gz|*.tgz|*.rar|*.7z|*.gz|*.bz2|*.xz)
      return 0
      ;;
  esac

  # --------------------------------------------------------------------------
  # 10) Documentos/binarios pesados generalmente innecesarios para revisión.
  #
  # Markdown, TXT, CSV pequeños, JSON, SQL, YAML, TS/JS, Dockerfiles, etc. quedan.
  # Office/PDF/multimedia quedan fuera porque pueden ser pesados o contener datos.
  # Si algún PDF o XLSX es estructural, se comparte caso por caso.
  # --------------------------------------------------------------------------
  case "$base" in
    *.pdf|*.doc|*.docx|*.xls|*.xlsx|*.ppt|*.pptx|*.odt|*.ods|*.odp)
      return 0
      ;;
    *.mp4|*.mov|*.avi|*.mkv|*.webm|*.mp3|*.wav|*.flac|*.m4a)
      return 0
      ;;
    *.png|*.jpg|*.jpeg|*.gif|*.webp|*.ico|*.svg)
      # Regla deliberada:
      # - Se permiten imágenes pequeñas en public/assets porque pueden ser parte
      #   de la UI.
      # - El límite de tamaño posterior evita meter librerías visuales pesadas.
      return 1
      ;;
    *.pbix|*.pbit)
      return 0
      ;;
  esac

  return 1
}

# ------------------------------------------------------------------------------
# Construcción de manifest exacto.
#
# Nota:
#   zip -@ consume rutas separadas por saltos de línea. Si un repositorio tiene
#   nombres con saltos de línea, el problema es el repositorio. No se soporta.
# ------------------------------------------------------------------------------

: > "${MANIFEST_FILE}"
: > "${WARNINGS_FILE}"

TOTAL_SCANNED=0
TOTAL_EXCLUDED_BY_RULE=0
TOTAL_EXCLUDED_BY_SIZE=0

while IFS= read -r -d '' file; do
  rel="${file#./}"
  TOTAL_SCANNED="$((TOTAL_SCANNED + 1))"

  if should_exclude_path "${rel}"; then
    TOTAL_EXCLUDED_BY_RULE="$((TOTAL_EXCLUDED_BY_RULE + 1))"
    continue
  fi

  size_bytes="$(wc -c < "${rel}" 2>/dev/null || echo 0)"
  size_bytes="$(echo "${size_bytes}" | tr -d ' ')"

  if [[ "${size_bytes}" =~ ^[0-9]+$ ]] && [[ "${size_bytes}" -gt "${MAX_FILE_BYTES}" ]]; then
    TOTAL_EXCLUDED_BY_SIZE="$((TOTAL_EXCLUDED_BY_SIZE + 1))"
    {
      echo "EXCLUIDO_POR_TAMANO: ${rel} (${size_bytes} bytes, limite ${MAX_FILE_MB} MB)"
    } >> "${WARNINGS_FILE}"
    continue
  fi

  printf '%s\n' "${rel}" >> "${MANIFEST_FILE}"
done < <(find . -type f -print0)

sort -o "${MANIFEST_FILE}" "${MANIFEST_FILE}"
cp "${MANIFEST_FILE}" "${FILES_FILE}"

FILE_COUNT="$(wc -l < "${MANIFEST_FILE}" | tr -d ' ')"

if [[ "${FILE_COUNT}" -eq 0 ]]; then
  echo "ERROR: el manifest quedó vacío. No se generará ZIP."
  exit 1
fi

# ------------------------------------------------------------------------------
# Generación de árbol desde manifest.
# Esto garantiza que tree/files/zip sigan la misma lógica.
# ------------------------------------------------------------------------------

if command -v python3 >/dev/null 2>&1; then
  python3 - "${MANIFEST_FILE}" "${TREE_FILE}" <<'PY'
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
tree_path = Path(sys.argv[2])

root = {}

for raw in manifest_path.read_text(encoding="utf-8", errors="replace").splitlines():
    parts = [p for p in raw.split("/") if p]
    node = root
    for part in parts:
        node = node.setdefault(part, {})

def emit(node, prefix=""):
    lines = []
    dirs = []
    files = []

    for name, child in node.items():
        if child:
            dirs.append((name, child))
        else:
            files.append((name, child))

    items = sorted(dirs, key=lambda kv: kv[0].lower()) + sorted(files, key=lambda kv: kv[0].lower())

    for idx, (name, child) in enumerate(items):
        is_last = idx == len(items) - 1
        connector = "└── " if is_last else "├── "
        lines.append(prefix + connector + name)

        if child:
            extension = "    " if is_last else "│   "
            lines.extend(emit(child, prefix + extension))

    return lines

lines = ["."]
lines.extend(emit(root))
tree_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
else
  {
    echo "."
    sed 's#^#./#' "${MANIFEST_FILE}"
  } > "${TREE_FILE}"
fi

# ------------------------------------------------------------------------------
# Warnings de seguridad.
#
# No se bloquea automáticamente salvo FAIL_ON_WARNINGS=1, porque puede haber
# falsos positivos. Pero si aparece un secreto real, NO se debe compartir el ZIP.
# ------------------------------------------------------------------------------

{
  echo "=============================================================================="
  echo "REPORTE DE EXPORTACION SANEADA"
  echo "=============================================================================="
  echo "Proyecto: ${PROJECT_ROOT}"
  echo "Nombre:   ${PROJECT_NAME}"
  echo "Fecha:    ${TIMESTAMP}"
  echo ""
  echo "Archivos escaneados:             ${TOTAL_SCANNED}"
  echo "Archivos excluidos por regla:     ${TOTAL_EXCLUDED_BY_RULE}"
  echo "Archivos excluidos por tamano:    ${TOTAL_EXCLUDED_BY_SIZE}"
  echo "Archivos incluidos en manifest:   ${FILE_COUNT}"
  echo "Limite por archivo:               ${MAX_FILE_MB} MB"
  echo ""

  echo "=============================================================================="
  echo "1) RUTAS SOSPECHOSAS INCLUIDAS"
  echo "=============================================================================="
  echo "Si aparece algo sensible real aqui, NO subas el ZIP."
  echo ""

  grep -Ein '(^|/)(\.env($|\.))|id_rsa|id_ed25519|\.pem$|\.key$|\.crt$|\.cer$|\.p12$|\.pfx$|\.jks$|credentials?|secrets?|tokens?|service-account|service_account|password|passwd' "${MANIFEST_FILE}" || true

  echo ""
  echo "=============================================================================="
  echo "2) PLANTILLAS DE ENTORNO INCLUIDAS"
  echo "=============================================================================="
  echo "Estas pueden ser utiles, pero deben revisarse manualmente."
  echo ""

  grep -Ein '(^|/)\.env\.(example|sample|template|local\.example|production\.example|development\.example|test\.example)$' "${MANIFEST_FILE}" || true

  echo ""
  echo "=============================================================================="
  echo "3) SQL INCLUIDO"
  echo "=============================================================================="
  echo "Los SQL se incluyen porque en tu flujo son codigo/consultas/migraciones."
  echo "Pero revisa que no sean dumps con datos reales."
  echo ""

  grep -Ein '\.sql$' "${MANIFEST_FILE}" || true

  echo ""
  echo "=============================================================================="
  echo "4) JSON INCLUIDOS RELACIONADOS CON N8N"
  echo "=============================================================================="
  echo "Los workflows n8n pueden contener nodos, URLs o referencias sensibles."
  echo "No deberian contener credenciales exportadas."
  echo ""

  grep -Ein '(^|/).*n8n.*\.json$|(^|/)workflows?/.*\.json$|(^|/)flows?/.*\.json$' "${MANIFEST_FILE}" || true

  echo ""
  echo "=============================================================================="
  echo "5) BUSQUEDA SUPERFICIAL DE POSIBLES SECRETOS EN ARCHIVOS DE TEXTO"
  echo "=============================================================================="
  echo "Puede generar falsos positivos. Si aparece un secreto real, NO subas el ZIP."
  echo ""

  while IFS= read -r rel; do
    # Evita leer archivos muy grandes o binarios. La detección MIME depende de
    # 'file'. Si no existe, se usa una lista de extensiones textuales.
    is_text=0

    if command -v file >/dev/null 2>&1; then
      mime="$(file --mime-type -b "${rel}" 2>/dev/null || true)"
      case "${mime}" in
        text/*|application/json|application/javascript|application/typescript|application/xml|application/x-shellscript|application/yaml|application/x-yaml)
          is_text=1
          ;;
      esac
    else
      case "${rel}" in
        *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json|*.yml|*.yaml|*.sql|*.md|*.txt|*.sh|*.prisma|*.env.example|*.env.sample|*.env.template|Dockerfile|*Dockerfile*)
          is_text=1
          ;;
      esac
    fi

    if [[ "${is_text}" -eq 1 ]]; then
      grep -InE 'DATABASE_URL=|DIRECT_URL=|POSTGRES_PASSWORD=|POSTGRES_USER=|NEXTAUTH_SECRET=|AUTH_SECRET=|JWT_SECRET=|SESSION_SECRET=|CLIENT_SECRET=|PRIVATE_KEY=|BEGIN PRIVATE KEY|api[_-]?key|access[_-]?token|refresh[_-]?token|bearer[[:space:]]+[A-Za-z0-9._-]+|password[[:space:]]*[:=]|passwd[[:space:]]*[:=]|secret[[:space:]]*[:=]|token[[:space:]]*[:=]' "${rel}" 2>/dev/null || true
    fi
  done < "${MANIFEST_FILE}"

  echo ""
  echo "=============================================================================="
  echo "6) ARCHIVOS EXCLUIDOS POR TAMANO"
  echo "=============================================================================="
  echo "Listado acumulado arriba como EXCLUIDO_POR_TAMANO, si aplica."
  echo ""

} >> "${WARNINGS_FILE}"

# Conteo simple de líneas sospechosas excluyendo encabezados.
WARNING_HITS="$(grep -Eic 'DATABASE_URL=|DIRECT_URL=|POSTGRES_PASSWORD=|NEXTAUTH_SECRET=|AUTH_SECRET=|JWT_SECRET=|CLIENT_SECRET=|PRIVATE_KEY=|BEGIN PRIVATE KEY|api[_-]?key|access[_-]?token|refresh[_-]?token|password[[:space:]]*[:=]|passwd[[:space:]]*[:=]|secret[[:space:]]*[:=]|token[[:space:]]*[:=]|EXCLUIDO_POR_TAMANO|credentials?|secrets?|tokens?' "${WARNINGS_FILE}" || true)"

if [[ "${FAIL_ON_WARNINGS}" == "1" && "${WARNING_HITS}" -gt 0 ]]; then
  echo "ERROR: se detectaron warnings y FAIL_ON_WARNINGS=1 está activo."
  echo "Revisa:"
  echo "  ${WARNINGS_FILE}"
  exit 1
fi

# ------------------------------------------------------------------------------
# Creación del ZIP exacto desde el manifest.
# ------------------------------------------------------------------------------

if [[ -f "${ZIP_FILE}" ]]; then
  rm -f "${ZIP_FILE}"
fi

zip -q -y "${ZIP_FILE}" -@ < "${MANIFEST_FILE}"
sha256sum "${ZIP_FILE}" > "${SHA_FILE}"

# ------------------------------------------------------------------------------
# Resumen final.
# ------------------------------------------------------------------------------

echo ""
echo "OK: exportacion saneada generada."
echo ""
echo "Proyecto:"
echo "  ${PROJECT_ROOT}"
echo ""
echo "Archivos generados:"
echo "  ZIP:       ${ZIP_FILE}"
echo "  Manifest:  ${MANIFEST_FILE}"
echo "  Files:     ${FILES_FILE}"
echo "  Tree:      ${TREE_FILE}"
echo "  Warnings:  ${WARNINGS_FILE}"
echo "  SHA256:    ${SHA_FILE}"
echo ""
echo "Resumen:"
echo "  Archivos escaneados:           ${TOTAL_SCANNED}"
echo "  Excluidos por regla:           ${TOTAL_EXCLUDED_BY_RULE}"
echo "  Excluidos por tamano:          ${TOTAL_EXCLUDED_BY_SIZE}"
echo "  Incluidos:                     ${FILE_COUNT}"
echo "  Warnings aproximados:          ${WARNING_HITS}"
echo ""
echo "Tamano del ZIP:"
du -h "${ZIP_FILE}"
echo ""
echo "Revision obligatoria antes de compartir:"
echo "  sed -n '1,260p' '${WARNINGS_FILE}'"
echo ""
echo "Si el reporte muestra secretos reales, NO subas el ZIP."
