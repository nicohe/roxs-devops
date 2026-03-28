#!/usr/bin/env bash

set -euo pipefail

echo "🚀 Roxs Voting App - Quick Start with Terraform"
echo ""

# Workspace selection
WORKSPACE="${1:-dev}"

echo "📋 Workspace: $WORKSPACE"
echo ""

# Create workspace if it doesn't exist
echo "1️⃣  Creating/selecting workspace..."
terraform workspace new "$WORKSPACE" 2>/dev/null || terraform workspace select "$WORKSPACE"

# Initialize Terraform
echo "2️⃣  Initializing Terraform..."
terraform init

# Validate configuration
echo "3️⃣  Validating configuration..."
terraform validate

# Format code
echo "4️⃣  Formatting code..."
terraform fmt -recursive

# Plan deployment
echo "5️⃣  Planning deployment..."
terraform plan -var-file="environments/${WORKSPACE}.tfvars"

# Ask for confirmation
read -p "🔄 Apply this configuration? (yes/no): " -r
echo
if [[ $REPLY =~ ^[Yy]es$ ]]; then
    echo "6️⃣  Applying configuration..."
    terraform apply -var-file="environments/${WORKSPACE}.tfvars"
    
    echo ""
    echo "✅ Deployment complete!"
    echo ""
    
    # Show outputs
    echo "📊 Deployment summary:"
    terraform output -json deployment_summary | jq '.'
    
    echo ""
    echo "🔍 Verifying deployment..."
    sleep 5
    ./scripts/verify-deployment.sh "$WORKSPACE"
else
    echo "❌ Deployment cancelled"
fi
