#!/usr/bin/env bash

set -Eeuo pipefail

environment="${1:-development}"

case "$environment" in
  development)
    project_name="roxs-voting-dev"
    compose_files=("-f" "docker-compose.yml")
    ;;
  staging)
    project_name="roxs-voting-staging"
    compose_files=("-f" "docker-compose.yml" "-f" "docker-compose.staging.yml")
    ;;
  production)
    project_name="roxs-voting-prod"
    compose_files=("-f" "docker-compose.yml" "-f" "docker-compose.prod.yml")
    ;;
  *)
    echo "Uso: $0 {development|staging|production}" >&2
    exit 1
    ;;
esac

if [[ ! -f .env ]]; then
  echo "Falta el archivo .env en la raiz del proyecto." >&2
  exit 1
fi

if [[ "$environment" != "development" ]]; then
  docker compose -p "$project_name" "${compose_files[@]}" pull
fi

docker compose -p "$project_name" "${compose_files[@]}" up -d --remove-orphans
docker compose -p "$project_name" "${compose_files[@]}" ps