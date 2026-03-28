#!/usr/bin/env bash

set -euo pipefail

WORKSPACE="${1:-dev}"
REPLICAS="${2:-2}"

echo "🔄 Escalando aplicación a $REPLICAS réplicas en workspace: $WORKSPACE"
echo ""

# Select workspace
terraform workspace select "$WORKSPACE"

# Apply with new replica count
terraform apply \
  -var-file="environments/${WORKSPACE}.tfvars" \
  -var="replica_count=$REPLICAS" \
  -auto-approve

echo ""
echo "✅ Escala actualizada a $REPLICAS réplicas"
echo ""

# Show containers
echo "📦 Contenedores activos:"
docker ps --filter "label=project=roxs-voting-app" --filter "label=environment=$WORKSPACE" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
