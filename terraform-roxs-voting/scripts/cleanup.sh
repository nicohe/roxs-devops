#!/usr/bin/env bash

set -euo pipefail

WORKSPACE="${1:-dev}"

echo "🧹 Limpiando infraestructura de workspace: $WORKSPACE"
echo ""

# Select workspace
terraform workspace select "$WORKSPACE"

# Destroy infrastructure
echo "⚠️  Esta acción destruirá toda la infraestructura en $WORKSPACE"
read -p "¿Continuar? (yes/no): " -r
echo

if [[ $REPLY =~ ^[Yy]es$ ]]; then
    terraform destroy -var-file="environments/${WORKSPACE}.tfvars" -auto-approve
    
    echo ""
    echo "✅ Infraestructura destruida"
    
    # Clean up dangling resources
    echo ""
    echo "🧹 Limpiando recursos huérfanos..."
    docker system prune -f
    
    echo "✅ Limpieza completa!"
else
    echo "❌ Operación cancelada"
fi
