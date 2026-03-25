#!/usr/bin/env bash

set -Eeuo pipefail

environment="${1:-production}"
timestamp="$(date +%Y%m%d-%H%M%S)"

case "$environment" in
  staging)
    project_name="roxs-voting-staging"
    compose_files=("-f" "docker-compose.yml" "-f" "docker-compose.staging.yml")
    ;;
  production)
    project_name="roxs-voting-prod"
    compose_files=("-f" "docker-compose.yml" "-f" "docker-compose.prod.yml")
    ;;
  *)
    echo "Uso: $0 {staging|production}" >&2
    exit 1
    ;;
esac

if [[ ! -f .env ]]; then
  echo "Falta el archivo .env en la raiz del proyecto." >&2
  exit 1
fi

set -a
source .env
set +a

mkdir -p backups

output_file="backups/${environment}-${DATABASE_NAME:-votes}-${timestamp}.sql"

database_container="$(docker compose -p "$project_name" "${compose_files[@]}" ps -q database)"

if [[ -z "$database_container" ]]; then
  echo "No hay contenedor de base de datos en ejecucion para $environment. Se omite el backup."
  exit 0
fi

docker compose -p "$project_name" "${compose_files[@]}" exec -T database \
  pg_dump -U "${DATABASE_USER:-postgres}" "${DATABASE_NAME:-votes}" > "$output_file"

echo "Backup generado en $output_file"