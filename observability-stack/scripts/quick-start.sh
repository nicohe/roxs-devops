#!/bin/bash

################################################################################
# Quick Start Script - Complete End-to-End Setup
# Runs complete setup, verification, port-forwards, and load test
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

clear
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║     🎯 Voting App - Quick Start                            ║"
echo "║     Complete Observability Stack Setup                    ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Ask for confirmation
log_warning "This script will:"
echo "  1. Deploy voting app to Kubernetes"
echo "  2. Configure Prometheus/Grafana monitoring"
echo "  3. Set up port forwards"
echo "  4. Run load test for 2 minutes"
echo "  5. Open dashboards in browser"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Cancelled by user"
    exit 0
fi

echo ""
log_step "STEP 1/6: Pre-flight Checks"
log_info "Checking prerequisites..."

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl not found. Please install kubectl first."
    exit 1
fi
log_success "kubectl ✓"

# Check cluster
if ! kubectl cluster-info &> /dev/null; then
    log_error "Cannot connect to Kubernetes cluster."
    log_info "Make sure your cluster is running (kind/minikube/Docker Desktop)"
    exit 1
fi
log_success "Kubernetes cluster ✓"

# Check monitoring namespace
if ! kubectl get namespace monitoring &> /dev/null; then
    log_warning "Namespace 'monitoring' not found."
    log_info "Installing Prometheus stack..."
    
    # Install Prometheus stack
    if ! command -v helm &> /dev/null; then
        log_error "helm not found. Please install helm first or create 'monitoring' namespace manually."
        exit 1
    fi
    
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts > /dev/null 2>&1
    helm repo update > /dev/null 2>&1
    
    log_info "Creating monitoring namespace..."
    kubectl create namespace monitoring
    
    log_info "Installing Prometheus stack (this may take 2-3 minutes)..."
    helm install prometheus prometheus-community/kube-prometheus-stack \
      --namespace monitoring \
      --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
      --set grafana.adminPassword=admin123 \
      --wait \
      --timeout 10m
fi
log_success "Monitoring stack ✓"

echo ""
log_step "STEP 2/6: Deploying Voting App"
log_info "Running setup script..."
./setup-observability.sh

echo ""
log_step "STEP 3/6: Verifying Deployment"
log_info "Running verification checks..."
./verify-stack.sh

if [ $? -ne 0 ]; then
    log_error "Verification failed. Check the output above."
    exit 1
fi

echo ""
log_step "STEP 4/6: Setting Up Port Forwards"
log_info "Starting port forwards in background..."
./port-forward.sh > /tmp/port-forward.log 2>&1 &
PF_PID=$!
sleep 5

# Verify port forwards are working
if ! curl -sf http://localhost:30080/healthz > /dev/null 2>&1; then
    log_warning "Vote service not accessible yet, waiting..."
    sleep 10
fi

log_success "Port forwards active (PID: $PF_PID)"

echo ""
log_step "STEP 5/6: Running Load Test"
log_info "Generating metrics for dashboards..."
export DURATION=120  # 2 minutes
export USERS=10
export VOTE_RATE=5
./load-test-demo.sh &
LOADTEST_PID=$!

echo ""
log_step "STEP 6/6: Opening Dashboards"
sleep 3
log_info "Opening observability dashboards in browser..."

# Detect OS and use appropriate open command
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    open http://localhost:30091 2>/dev/null || true
    open http://localhost:30090/targets 2>/dev/null || true
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    xdg-open http://localhost:30091 2>/dev/null || true
    xdg-open http://localhost:30090/targets 2>/dev/null || true
fi

# Wait for load test to finish
wait $LOADTEST_PID

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║     ✅ Quick Start Complete!                               ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

log_success "Your observability stack is fully operational!"
echo ""

log_info "Access URLs:"
echo ""
echo "  📊 Grafana Dashboards:"
echo "     http://localhost:30091"
echo "     Login: admin / admin123"
echo ""
echo "     Business Dashboard:"
echo "     http://localhost:30091/d/voting-business"
echo ""
echo "     Technical Dashboard:"
echo "     http://localhost:30091/d/voting-technical"
echo ""
echo "  🎯 Prometheus:"
echo "     Targets: http://localhost:30090/targets"
echo "     Alerts:  http://localhost:30090/alerts"
echo "     Graph:   http://localhost:30090/graph"
echo ""
echo "  🗳️  Voting App:"
echo "     Vote:   http://localhost:30080"
echo "     Result: http://localhost:30081"
echo ""

log_info "Next Steps:"
echo ""
echo "  1. Explore the Grafana dashboards"
echo "  2. Cast some votes manually at http://localhost:30080"
echo "  3. Watch metrics update in real-time"
echo "  4. Check Prometheus targets are scraped successfully"
echo "  5. Review the demo script: ../DIA56-DEMO-SCRIPT.md"
echo ""

log_warning "To stop port forwards: pkill -f 'kubectl port-forward'"
log_warning "To clean up: kubectl delete namespace voting-app"
echo ""

log_success "Happy observing! 🔍📈"
echo ""
