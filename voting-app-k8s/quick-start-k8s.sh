#!/bin/bash
# Script de inicio rápido para el Día 42 - CI/CD con Kubernetes
# Autor: Nicolas Herrera
# Uso: ./quick-start-k8s.sh [dev|staging|prod|local]

set -e

ENVIRONMENT=${1:-dev}
NAMESPACE="voting-app-${ENVIRONMENT}"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🚀 Roxs Voting App - Kubernetes Deployment${NC}"
echo -e "${BLUE}   Environment: ${ENVIRONMENT}${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Función para imprimir mensajes
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar kubectl
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl no está instalado. Por favor instálalo primero."
    exit 1
fi

# Verificar conexión al clúster
log_info "Verificando conexión al clúster de Kubernetes..."
if ! kubectl cluster-info &> /dev/null; then
    log_error "No se puede conectar al clúster de Kubernetes."
    log_info "Asegúrate de tener un clúster funcionando (minikube, kind, etc.)"
    exit 1
fi
log_success "Conexión al clúster exitosa"

# Función para deploy local (sin GitHub)
deploy_local() {
    log_info "Modo local detectado - construyendo imágenes localmente..."
    
    # Verificar si estamos en Minikube
    if kubectl config current-context | grep -q "minikube"; then
        log_info "Minikube detectado - usando docker daemon de Minikube..."
        eval $(minikube docker-env)
    fi
    
    # Construir imágenes
    log_info "Construyendo imagen de Vote..."
    docker build -t vote:local ./roxs-voting-app/vote
    
    log_info "Construyendo imagen de Worker..."
    docker build -t worker:local ./roxs-voting-app/worker
    
    log_info "Construyendo imagen de Result..."
    docker build -t result:local ./roxs-voting-app/result
    
    log_success "Imágenes construidas exitosamente"
    
    # Aplicar manifiestos originales
    log_info "Aplicando manifiestos de Kubernetes..."
    for file in voting-app-k8s/0*.yaml; do
        log_info "Aplicando $(basename $file)..."
        kubectl apply -f "$file"
    done
}

# Función para deploy con Kustomize
deploy_with_kustomize() {
    local env=$1
    local overlay_path="voting-app-k8s/overlays/${env}"
    
    if [ ! -d "$overlay_path" ]; then
        log_error "Overlay no encontrado para ambiente: $env"
        log_info "Ambientes disponibles: dev, staging, prod"
        exit 1
    fi
    
    # Actualizar referencias de imágenes si es necesario
    log_info "Preparando configuración de Kustomize..."
    cd "$overlay_path"
    
    # Obtener el usuario de GitHub del repositorio remoto
    if git remote -v | grep -q "github.com"; then
        GITHUB_USER=$(git remote get-url origin | sed -n 's/.*github.com[:/]\([^/]*\)\/.*/\1/p')
        log_info "Usuario de GitHub detectado: $GITHUB_USER"
        
        # Crear una copia temporal con el usuario actualizado
        cp kustomization.yaml kustomization.yaml.bak
        sed -i.tmp "s|GITHUB_USER|${GITHUB_USER}|g" kustomization.yaml
        rm -f kustomization.yaml.tmp
    else
        log_warning "Repositorio Git no detectado, asumiendo imágenes locales"
    fi
    
    cd - > /dev/null
    
    # Aplicar con Kustomize
    log_info "Aplicando manifiestos con Kustomize..."
    kubectl apply -k "$overlay_path"
    
    # Restaurar backup si existe
    if [ -f "$overlay_path/kustomization.yaml.bak" ]; then
        mv "$overlay_path/kustomization.yaml.bak" "$overlay_path/kustomization.yaml"
    fi
}

# Función para esperar deployments
wait_for_deployments() {
    local namespace=$1
    
    log_info "Esperando a que los deployments estén listos..."
    
    deployments=("postgres" "redis" "vote" "worker" "result")
    
    for deployment in "${deployments[@]}"; do
        local full_name="${deployment}-${ENVIRONMENT}"
        if [ "$ENVIRONMENT" == "local" ]; then
            full_name="${deployment}"
        fi
        
        log_info "Esperando deployment: $full_name"
        
        if kubectl rollout status deployment/"$full_name" -n "$namespace" --timeout=5m; then
            log_success "$full_name está listo"
        else
            log_error "$full_name falló al estar listo"
            log_info "Logs recientes:"
            kubectl logs -n "$namespace" -l app="${deployment}" --tail=20
            return 1
        fi
    done
}

# Función para mostrar información de acceso
show_access_info() {
    local namespace=$1
    
    echo ""
    log_success "¡Deployment completado exitosamente!"
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}📊 Estado del Deployment${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    kubectl get all -n "$namespace"
    
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}🌐 Acceso a las Aplicaciones${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    
    # Obtener NodePorts
    VOTE_NODEPORT=$(kubectl get svc -n "$namespace" -o jsonpath='{.items[?(@.metadata.name=="vote-service" || @.metadata.name=="vote-service-'${ENVIRONMENT}'")].spec.ports[0].nodePort}')
    RESULT_NODEPORT=$(kubectl get svc -n "$namespace" -o jsonpath='{.items[?(@.metadata.name=="result-service" || @.metadata.name=="result-service-'${ENVIRONMENT}'")].spec.ports[0].nodePort}')
    
    # Verificar si estamos en Minikube
    if kubectl config current-context | grep -q "minikube"; then
        MINIKUBE_IP=$(minikube ip)
        echo -e "${GREEN}Vote App:   http://${MINIKUBE_IP}:${VOTE_NODEPORT}${NC}"
        echo -e "${GREEN}Result App: http://${MINIKUBE_IP}:${RESULT_NODEPORT}${NC}"
        echo ""
        log_info "O usa Minikube service para abrir en el navegador:"
        echo "  minikube service vote-service${ENVIRONMENT:+-${ENVIRONMENT}} -n $namespace"
        echo "  minikube service result-service${ENVIRONMENT:+-${ENVIRONMENT}} -n $namespace"
    else
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
        if [ -z "$NODE_IP" ]; then
            NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
        fi
        echo -e "${GREEN}Vote App:   http://${NODE_IP}:${VOTE_NODEPORT}${NC}"
        echo -e "${GREEN}Result App: http://${NODE_IP}:${RESULT_NODEPORT}${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    log_info "Comandos útiles:"
    echo "  Ver pods:         kubectl get pods -n $namespace"
    echo "  Ver logs (vote):  kubectl logs -n $namespace -l app=vote --tail=50 -f"
    echo "  Ver logs (worker):kubectl logs -n $namespace -l app=worker --tail=50 -f"
    echo "  Ver eventos:      kubectl get events -n $namespace --sort-by='.lastTimestamp'"
    echo "  Eliminar todo:    kubectl delete namespace $namespace"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
}

# Main
case $ENVIRONMENT in
    local)
        NAMESPACE="voting-app"
        deploy_local
        wait_for_deployments "$NAMESPACE"
        show_access_info "$NAMESPACE"
        ;;
    dev|staging|prod)
        deploy_with_kustomize "$ENVIRONMENT"
        wait_for_deployments "$NAMESPACE"
        show_access_info "$NAMESPACE"
        ;;
    *)
        log_error "Ambiente inválido: $ENVIRONMENT"
        echo ""
        echo "Uso: $0 [local|dev|staging|prod]"
        echo ""
        echo "  local   - Deploy local usando imágenes locales (para testing)"
        echo "  dev     - Deploy a ambiente dev usando Kustomize"
        echo "  staging - Deploy a ambiente staging usando Kustomize"
        echo "  prod    - Deploy a ambiente prod usando Kustomize"
        echo ""
        exit 1
        ;;
esac

log_success "Script completado exitosamente"
