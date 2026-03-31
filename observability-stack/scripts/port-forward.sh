#!/bin/bash

################################################################################
# Port Forward Setup Script
# Creates port forwards to access all observability services
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Port Forward Setup                                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Function to kill existing port forwards
cleanup() {
    log_info "Cleaning up existing port forwards..."
    pkill -f "kubectl port-forward" || true
    sleep 2
}

# Cleanup on exit
trap cleanup EXIT INT TERM

# Kill any existing port forwards
cleanup

log_info "Starting port forwards..."
echo ""

# Voting App
log_info "Setting up Voting App access..."
kubectl port-forward -n voting-app svc/vote 30080:80 > /dev/null 2>&1 &
sleep 1
kubectl port-forward -n voting-app svc/result 30081:80 > /dev/null 2>&1 &
sleep 1
log_success "Vote:   http://localhost:30080"
log_success "Result: http://localhost:30081"

# Prometheus
log_info "Setting up Prometheus access..."
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 30090:9090 > /dev/null 2>&1 &
sleep 1
log_success "Prometheus: http://localhost:30090"

# Grafana
log_info "Setting up Grafana access..."
kubectl port-forward -n monitoring svc/prometheus-grafana 30091:80 > /dev/null 2>&1 &
sleep 1
log_success "Grafana:    http://localhost:30091 (admin / admin123)"

# Jaeger (if exists)
if kubectl get namespace tracing > /dev/null 2>&1; then
    log_info "Setting up Jaeger access..."
    kubectl port-forward -n tracing svc/jaeger-query 16686:16686 > /dev/null 2>&1 &
    sleep 1
    log_success "Jaeger:     http://localhost:16686"
fi

# Kibana (if exists)
if kubectl get namespace logging > /dev/null 2>&1; then
    log_info "Setting up Kibana access..."
    kubectl port-forward -n logging svc/kibana-kb-http 30093:5601 > /dev/null 2>&1 &
    sleep 1
    log_success "Kibana:     http://localhost:30093"
fi

echo ""
log_success "═══════════════════════════════════════════════════════════"
log_success "All port forwards are active!"
log_success "═══════════════════════════════════════════════════════════"
echo ""

log_info "Quick Links:"
echo ""
echo "  📊 Dashboards:"
echo "     Business:  http://localhost:30091/d/voting-business"
echo "     Technical: http://localhost:30091/d/voting-technical"
echo ""
echo "  🎯 Targets:"
echo "     http://localhost:30090/targets"
echo ""
echo "  🚨 Alerts:"
echo "     http://localhost:30090/alerts"
echo ""
echo "  🗳️  Voting:"
echo "     http://localhost:30080"
echo ""
echo "  📊 Results:"
echo "     http://localhost:30081"
echo ""

log_warning "Press Ctrl+C to stop all port forwards"
echo ""

# Keep script running
wait
