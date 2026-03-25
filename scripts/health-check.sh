#!/usr/bin/env bash

set -Eeuo pipefail

environment="${1:-development}"
max_attempts="${MAX_HEALTH_ATTEMPTS:-18}"
sleep_seconds="${HEALTH_RETRY_SECONDS:-10}"

if [[ ! -f .env && -f .env.example ]]; then
  cp .env.example .env
fi

case "$environment" in
  development)
    project_name="roxs-voting-dev"
    compose_files=("-f" "docker-compose.yml")
    vote_url="${VOTE_HEALTH_URL:-http://localhost/healthz}"
    result_url="${RESULT_HEALTH_URL:-http://localhost:3000/healthz}"
    ;;
  staging)
    project_name="roxs-voting-staging"
    compose_files=("-f" "docker-compose.yml" "-f" "docker-compose.staging.yml")
    vote_url="${VOTE_HEALTH_URL:-http://localhost:8080/healthz}"
    result_url="${RESULT_HEALTH_URL:-http://localhost:8081/healthz}"
    ;;
  production)
    project_name="roxs-voting-prod"
    compose_files=("-f" "docker-compose.yml" "-f" "docker-compose.prod.yml")
    vote_url="${VOTE_HEALTH_URL:-http://localhost/healthz}"
    result_url="${RESULT_HEALTH_URL:-http://localhost:3000/healthz}"
    ;;
  *)
    echo "Uso: $0 {development|staging|production}" >&2
    exit 1
    ;;
esac

services=(vote worker result redis database)

check_service_health() {
  local service="$1"
  local container_id
  local state

  container_id="$(docker compose -p "$project_name" "${compose_files[@]}" ps -q "$service")"

  if [[ -z "$container_id" ]]; then
    echo "Servicio $service no encontrado" >&2
    return 1
  fi

  state="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container_id")"

  if [[ "$state" != "healthy" && "$state" != "running" ]]; then
    echo "Servicio $service en estado $state" >&2
    return 1
  fi

  return 0
}

for attempt in $(seq 1 "$max_attempts"); do
  failed=0

  for service in "${services[@]}"; do
    if ! check_service_health "$service"; then
      failed=1
    fi
  done

  if ! curl -fsS "$vote_url" >/dev/null; then
    echo "Vote health endpoint no responde: $vote_url" >&2
    failed=1
  fi

  if ! curl -fsS "$result_url" >/dev/null; then
    echo "Result health endpoint no responde: $result_url" >&2
    failed=1
  fi

  if [[ "$failed" -eq 0 ]]; then
    echo "Health checks OK para $environment"
    exit 0
  fi

  echo "Reintento $attempt/$max_attempts en ${sleep_seconds}s"
  sleep "$sleep_seconds"
done

echo "Health checks fallaron para $environment" >&2
docker compose -p "$project_name" "${compose_files[@]}" ps >&2
exit 1