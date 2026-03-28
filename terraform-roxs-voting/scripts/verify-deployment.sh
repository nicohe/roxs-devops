#!/usr/bin/env bash

set -euo pipefail

WORKSPACE="${1:-dev}"

echo "🔍 Verificando despliegue para workspace: $WORKSPACE"
echo ""

# Determine ports based on workspace
case "$WORKSPACE" in
  dev)
    VOTE_PORT=8080
    RESULT_PORT=3000
    ;;
  staging)
    VOTE_PORT=8081
    RESULT_PORT=3001
    ;;
  prod)
    VOTE_PORT=80
    RESULT_PORT=3000
    ;;
  *)
    echo "❌ Workspace desconocido: $WORKSPACE"
    exit 1
    ;;
esac

# Check containers
echo "📦 Verificando contenedores activos..."
CONTAINERS=$(docker ps --filter "label=project=roxs-voting-app" --filter "label=environment=$WORKSPACE" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}")

if [ -z "$CONTAINERS" ]; then
    echo "❌ No se encontraron contenedores activos"
    exit 1
fi

echo "$CONTAINERS"
echo ""

# Check vote service
echo "🗳️  Verificando servicio de votación..."
if curl -fsS "http://localhost:${VOTE_PORT}/healthz" >/dev/null 2>&1; then
    echo "✅ Vote service: OK (http://localhost:${VOTE_PORT})"
else
    echo "❌ Vote service: FAILED"
    exit 1
fi

# Check result service
echo "📊 Verificando servicio de resultados..."
if curl -fsS "http://localhost:${RESULT_PORT}/healthz" >/dev/null 2>&1; then
    echo "✅ Result service: OK (http://localhost:${RESULT_PORT})"
else
    echo "❌ Result service: FAILED"
    exit 1
fi

# Test vote functionality
echo "🧪 Probando funcionalidad de votación..."
if curl -fsS -X POST "http://localhost:${VOTE_PORT}/" -d 'vote=a' >/dev/null 2>&1; then
    echo "✅ Votación: OK"
else
    echo "❌ Votación: FAILED"
    exit 1
fi

# Check database connectivity
echo "🗄️  Verificando base de datos..."
DB_CONTAINER=$(docker ps --filter "label=project=roxs-voting-app" --filter "label=service=database" --filter "label=environment=$WORKSPACE" --format "{{.Names}}" | head -n1)

if [ -n "$DB_CONTAINER" ]; then
    if docker exec "$DB_CONTAINER" pg_isready -U postgres >/dev/null 2>&1; then
        echo "✅ Database: OK"
    else
        echo "❌ Database: FAILED"
        exit 1
    fi
fi

# Check Redis
echo "⚡ Verificando Redis..."
REDIS_CONTAINER=$(docker ps --filter "label=project=roxs-voting-app" --filter "label=service=cache" --filter "label=environment=$WORKSPACE" --format "{{.Names}}" | head -n1)

if [ -n "$REDIS_CONTAINER" ]; then
    if docker exec "$REDIS_CONTAINER" redis-cli ping >/dev/null 2>&1; then
        echo "✅ Redis: OK"
    else
        echo "❌ Redis: FAILED"
        exit 1
    fi
fi

# Show logs summary
echo ""
echo "📝 Últimos logs (últimas 5 líneas por servicio):"
for container in $(docker ps --filter "label=project=roxs-voting-app" --filter "label=environment=$WORKSPACE" --format "{{.Names}}"); do
    echo ""
    echo "━━━ $container ━━━"
    docker logs "$container" --tail 5 2>&1 || echo "No logs available"
done

echo ""
echo "✅ ¡Verificación completa exitosa!"
echo ""
echo "🌐 URLs de acceso:"
echo "   Vote:   http://localhost:${VOTE_PORT}"
echo "   Result: http://localhost:${RESULT_PORT}"
