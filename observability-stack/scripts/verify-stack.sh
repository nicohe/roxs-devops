#!/bin/bash

################################################################################
# Verify Observability Stack
# Checks all components are working correctly
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

check_pass() {
    log_success "$1"
    ((PASS_COUNT++))
}

check_fail() {
    log_error "$1"
    ((FAIL_COUNT++))
}

check_warn() {
    log_warning "$1"
    ((WARN_COUNT++))
}

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Observability Stack Verification                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# 1. Cluster connectivity
log_info "Checking Kubernetes cluster..."
if kubectl cluster-info > /dev/null 2>&1; then
    check_pass "Kubernetes cluster is accessible"
else
    check_fail "Cannot connect to Kubernetes cluster"
    exit 1
fi

# 2. Namespaces
log_info "Checking namespaces..."
if kubectl get namespace voting-app > /dev/null 2>&1; then
    check_pass "Namespace 'voting-app' exists"
else
    check_fail "Namespace 'voting-app' not found"
fi

if kubectl get namespace monitoring > /dev/null 2>&1; then
    check_pass "Namespace 'monitoring' exists"
else
    check_warn "Namespace 'monitoring' not found (Prometheus stack may not be installed)"
fi

# 3. Voting App Pods
log_info "Checking voting app pods..."
VOTE_PODS=$(kubectl get pods -n voting-app -l app=vote -o json | jq -r '.items | length')
RESULT_PODS=$(kubectl get pods -n voting-app -l app=result -o json | jq -r '.items | length')
WORKER_PODS=$(kubectl get pods -n voting-app -l app=worker -o json | jq -r '.items | length')
REDIS_PODS=$(kubectl get pods -n voting-app -l app=redis -o json | jq -r '.items | length')
POSTGRES_PODS=$(kubectl get pods -n voting-app -l app=postgres -o json | jq -r '.items | length')

if [ "$VOTE_PODS" -gt 0 ]; then
    check_pass "Vote pods running ($VOTE_PODS replicas)"
else
    check_fail "No vote pods found"
fi

if [ "$RESULT_PODS" -gt 0 ]; then
    check_pass "Result pods running ($RESULT_PODS replicas)"
else
    check_fail "No result pods found"
fi

if [ "$WORKER_PODS" -gt 0 ]; then
    check_pass "Worker pod running"
else
    check_fail "No worker pod found"
fi

if [ "$REDIS_PODS" -gt 0 ]; then
    check_pass "Redis pod running"
else
    check_fail "No Redis pod found"
fi

if [ "$POSTGRES_PODS" -gt 0 ]; then
    check_pass "PostgreSQL pod running"
else
    check_fail "No PostgreSQL pod found"
fi

# 4. Pod Health
log_info "Checking pod health..."
UNHEALTHY_PODS=$(kubectl get pods -n voting-app -o json | jq -r '.items[] | select(.status.phase != "Running") | .metadata.name')
if [ -z "$UNHEALTHY_PODS" ]; then
    check_pass "All pods are in Running state"
else
    check_warn "Some pods are not running: $UNHEALTHY_PODS"
fi

# 5. Services
log_info "Checking services..."
if kubectl get svc -n voting-app vote > /dev/null 2>&1; then
    check_pass "Vote service exists"
else
    check_fail "Vote service not found"
fi

if kubectl get svc -n voting-app result > /dev/null 2>&1; then
    check_pass "Result service exists"
else
    check_fail "Result service not found"
fi

# 6. ServiceMonitors
log_info "Checking ServiceMonitors..."
SERVICEMONITORS=$(kubectl get servicemonitors -n voting-app 2>/dev/null | grep -c "vote\|result\|worker" || echo "0")
if [ "$SERVICEMONITORS" -ge 3 ]; then
    check_pass "ServiceMonitors configured ($SERVICEMONITORS found)"
else
    check_warn "Expected 3 ServiceMonitors, found $SERVICEMONITORS"
fi

# 7. PrometheusRules
log_info "Checking PrometheusRules..."
if kubectl get prometheusrules -n voting-app voting-app-alerts > /dev/null 2>&1; then
    check_pass "PrometheusRules 'voting-app-alerts' exists"
else
    check_warn "PrometheusRules not found (alerts not configured)"
fi

# 8. Grafana Dashboards
log_info "Checking Grafana dashboards..."
if kubectl get configmap -n monitoring voting-business-dashboard > /dev/null 2>&1; then
    check_pass "Business dashboard ConfigMap exists"
else
    check_warn "Business dashboard not imported"
fi

if kubectl get configmap -n monitoring voting-technical-dashboard > /dev/null 2>&1; then
    check_pass "Technical dashboard ConfigMap exists"
else
    check_warn "Technical dashboard not imported"
fi

# 9. Endpoint connectivity
log_info "Checking service endpoints..."

# Try to access vote service health endpoint
if kubectl exec -n voting-app deployment/vote -- curl -sf http://localhost:80/healthz > /dev/null 2>&1; then
    check_pass "Vote service health endpoint responding"
else
    check_warn "Vote service health check failed"
fi

# Try to access result service health endpoint
if kubectl exec -n voting-app deployment/result -- curl -sf http://localhost:3000/healthz > /dev/null 2>&1; then
    check_pass "Result service health endpoint responding"
else
    check_warn "Result service health check failed"
fi

# 10. Metrics endpoints
log_info "Checking metrics endpoints..."

# Check if vote metrics endpoint is accessible
if kubectl exec -n voting-app deployment/vote -- curl -sf http://localhost:80/metrics > /dev/null 2>&1; then
    check_pass "Vote /metrics endpoint accessible"
else
    check_fail "Vote /metrics endpoint not accessible"
fi

# Check if worker metrics endpoint is accessible
if kubectl exec -n voting-app deployment/worker -- curl -sf http://localhost:3000/metrics > /dev/null 2>&1; then
    check_pass "Worker /metrics endpoint accessible"
else
    check_fail "Worker /metrics endpoint not accessible"
fi

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "              Verification Summary"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "  ✓ Passed:  $PASS_COUNT"
echo "  ! Warnings: $WARN_COUNT"
echo "  ✗ Failed:  $FAIL_COUNT"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    if [ $WARN_COUNT -eq 0 ]; then
        log_success "All checks passed! 🎉"
        echo ""
        log_info "Your observability stack is fully operational."
        log_info "Run './load-test-demo.sh' to generate metrics for dashboards."
    else
        log_warning "Basic setup is working, but some optional components have warnings."
        log_info "Review warnings above. System should still function."
    fi
else
    log_error "Some critical checks failed. Please review the errors above."
    exit 1
fi

echo ""
