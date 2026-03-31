#!/bin/bash

################################################################################
# Setup Observability Stack for Voting App
# Automated deployment script for Day 56 challenge
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
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Voting App - Observability Stack Setup                  ║"
echo "║   Day 56 - End-to-End Observability Integration           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Verify prerequisites
log_info "Step 1/8: Verifying prerequisites..."

if ! command -v kubectl &> /dev/null; then
    log_error "kubectl not found. Please install kubectl first."
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    log_error "Cannot connect to Kubernetes cluster. Is it running?"
    exit 1
fi
log_success "Kubernetes cluster is accessible ✓"

# Check for monitoring namespace (Prometheus stack)
if ! kubectl get namespace monitoring &> /dev/null; then
    log_warning "Namespace 'monitoring' not found."
    log_info "You need to install Prometheus stack first (Day 55)."
    read -p "Do you want to continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    log_success "Monitoring namespace exists ✓"
fi

# Step 2: Create voting-app namespace
log_info "Step 2/8: Creating voting-app namespace..."
kubectl apply -f ../kubernetes/01-namespace.yaml
log_success "Namespace created ✓"

# Step 3: Deploy databases
log_info "Step 3/8: Deploying Redis and PostgreSQL..."
kubectl apply -f ../kubernetes/02-databases.yaml

# Wait for databases to be ready
log_info "Waiting for databases to be ready..."
kubectl wait --for=condition=ready pod -l app=redis -n voting-app --timeout=120s
kubectl wait --for=condition=ready pod -l app=postgres -n voting-app --timeout=120s
log_success "Databases are ready ✓"

# Step 4: Deploy voting app services
log_info "Step 4/8: Deploying voting app services..."
kubectl apply -f ../kubernetes/03-voting-app.yaml

# Wait for apps to be ready
log_info "Waiting for voting app pods to be ready..."
sleep 10  # Give deployments time to create pods
kubectl wait --for=condition=ready pod -l app=vote -n voting-app --timeout=180s || log_warning "Vote pods might still be starting..."
kubectl wait --for=condition=ready pod -l app=result -n voting-app --timeout=180s || log_warning "Result pods might still be starting..."
kubectl wait --for=condition=ready pod -l app=worker -n voting-app --timeout=180s || log_warning "Worker pod might still be starting..."
log_success "Voting app deployed ✓"

# Step 5: Apply ServiceMonitors
log_info "Step 5/8: Configuring Prometheus ServiceMonitors..."
kubectl apply -f ../kubernetes/04-servicemonitors.yaml
log_success "ServiceMonitors configured ✓"

# Step 6: Apply PrometheusRules (Alerts)
log_info "Step 6/8: Configuring alerting rules..."
kubectl apply -f ../prometheus-rules/voting-app-alerts.yaml
log_success "Alerting rules configured ✓"

# Step 7: Import Grafana dashboards
log_info "Step 7/8: Importing Grafana dashboards..."

# Check if ConfigMaps already exist
if kubectl get configmap voting-business-dashboard -n monitoring &> /dev/null; then
    log_warning "Business dashboard ConfigMap exists, deleting..."
    kubectl delete configmap voting-business-dashboard -n monitoring
fi

if kubectl get configmap voting-technical-dashboard -n monitoring &> /dev/null; then
    log_warning "Technical dashboard ConfigMap exists, deleting..."
    kubectl delete configmap voting-technical-dashboard -n monitoring
fi

# Create ConfigMaps
kubectl create configmap voting-business-dashboard \
    --from-file=../grafana-dashboards/business-dashboard.json \
    -n monitoring

kubectl create configmap voting-technical-dashboard \
    --from-file=../grafana-dashboards/technical-dashboard.json \
    -n monitoring

# Label for auto-discovery
kubectl label configmap voting-business-dashboard grafana_dashboard=1 -n monitoring
kubectl label configmap voting-technical-dashboard grafana_dashboard=1 -n monitoring
log_success "Grafana dashboards imported ✓"

# Step 8: Verify deployment
log_info "Step 8/8: Verifying deployment..."
echo ""

# Check pods
log_info "Pod Status:"
kubectl get pods -n voting-app

# Check services
echo ""
log_info "Service Status:"
kubectl get svc -n voting-app

# Check ServiceMonitors
echo ""
log_info "ServiceMonitors:"
kubectl get servicemonitors -n voting-app

echo ""
log_success "═══════════════════════════════════════════════════════════"
log_success "✓ Observability Stack Setup Complete!"
log_success "═══════════════════════════════════════════════════════════"
echo ""

# Access information
log_info "Access URLs (may require port-forwarding):"
echo ""
echo "  📊 Grafana Dashboards:"
echo "     kubectl port-forward -n monitoring svc/prometheus-grafana 30091:80"
echo "     http://localhost:30091"
echo "     Credentials: admin / admin123"
echo ""
echo "  🎯 Prometheus UI:"
echo "     kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 30090:9090"
echo "     http://localhost:30090"
echo ""
echo "  🗳️  Voting App:"
echo "     Vote:   http://localhost:30080"
echo "     Result: http://localhost:30081"
echo ""

log_info "Next Steps:"
echo ""
echo "  1. Set up port forwards (if needed):"
echo "     ./setup-port-forwards.sh"
echo ""
echo "  2. Run load test to generate metrics:"
echo "     ./load-test-demo.sh"
echo ""
echo "  3. View Grafana dashboards:"
echo "     - Voting App - Business Dashboard"
echo "     - Voting App - Technical SRE Dashboard"
echo ""
echo "  4. Check Prometheus targets:"
echo "     http://localhost:30090/targets"
echo "     Look for 'voting-app' services"
echo ""
echo "  5. Review alerts configuration:"
echo "     http://localhost:30090/alerts"
echo ""

log_success "Happy Observing! 🔍📈"
echo ""
