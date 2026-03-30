#!/bin/bash

# Script de despliegue automatizado para roxs-voting-app en Kubernetes
# Despliega todos los componentes en el orden correcto

set -e  # Detener el script si hay algún error

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Roxs Voting App - Deployment K8s   ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Verificar que minikube está corriendo
echo -e "${YELLOW}Verificando que Minikube está corriendo...${NC}"
if ! minikube status > /dev/null 2>&1; then
    echo -e "${RED}❌ Minikube no está corriendo. Ejecuta: minikube start${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Minikube está corriendo${NC}"
echo ""

# Verificar que kubectl está disponible
echo -e "${YELLOW}Verificando kubectl...${NC}"
if ! kubectl version --client > /dev/null 2>&1; then
    echo -e "${RED}❌ kubectl no está disponible${NC}"
    exit 1
fi
echo -e "${GREEN}✅ kubectl está disponible${NC}"
echo ""

# 1. Crear namespace
echo -e "${BLUE}📁 Paso 1: Creando namespace...${NC}"
kubectl apply -f 01-namespace.yaml
echo -e "${GREEN}✅ Namespace creado${NC}"
echo ""

# 2. Crear almacenamiento persistente
echo -e "${BLUE}💾 Paso 2: Configurando almacenamiento persistente...${NC}"
kubectl apply -f 02-storage.yaml
echo -e "${GREEN}✅ Almacenamiento configurado${NC}"
echo ""

# 3. Crear ConfigMaps y Secrets
echo -e "${BLUE}⚙️  Paso 3: Creando configuraciones y secretos...${NC}"
kubectl apply -f 03-configs-secrets.yaml
echo -e "${GREEN}✅ Configuraciones creadas${NC}"
echo ""

# 4. Desplegar PostgreSQL
echo -e "${BLUE}🗃️  Paso 4: Desplegando PostgreSQL...${NC}"
kubectl apply -f 04-postgres.yaml
echo -e "${YELLOW}Esperando que PostgreSQL esté listo...${NC}"
kubectl wait --for=condition=ready pod -l app=postgres -n voting-app --timeout=120s
echo -e "${GREEN}✅ PostgreSQL desplegado y listo${NC}"
echo ""

# 5. Desplegar Redis
echo -e "${BLUE}🔄 Paso 5: Desplegando Redis...${NC}"
kubectl apply -f 05-redis.yaml
echo -e "${YELLOW}Esperando que Redis esté listo...${NC}"
kubectl wait --for=condition=ready pod -l app=redis -n voting-app --timeout=60s
echo -e "${GREEN}✅ Redis desplegado y listo${NC}"
echo ""

# 6. Desplegar Vote App
echo -e "${BLUE}🗳️  Paso 6: Desplegando Vote App...${NC}"
kubectl apply -f 06-vote.yaml
echo -e "${YELLOW}Esperando que Vote App esté listo...${NC}"
kubectl wait --for=condition=ready pod -l app=vote -n voting-app --timeout=90s
echo -e "${GREEN}✅ Vote App desplegado y listo${NC}"
echo ""

# 7. Desplegar Worker
echo -e "${BLUE}⚙️  Paso 7: Desplegando Worker...${NC}"
kubectl apply -f 07-worker.yaml
echo -e "${YELLOW}Esperando que Worker esté listo...${NC}"
sleep 10  # Worker no tiene readiness probe, esperar unos segundos
echo -e "${GREEN}✅ Worker desplegado${NC}"
echo ""

# 8. Desplegar Result App
echo -e "${BLUE}📊 Paso 8: Desplegando Result App...${NC}"
kubectl apply -f 08-result.yaml
echo -e "${YELLOW}Esperando que Result App esté listo...${NC}"
kubectl wait --for=condition=ready pod -l app=result -n voting-app --timeout=90s
echo -e "${GREEN}✅ Result App desplegado y listo${NC}"
echo ""

# Mostrar resumen del despliegue
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   📊 RESUMEN DEL DESPLIEGUE          ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}Pods desplegados:${NC}"
kubectl get pods -n voting-app
echo ""

echo -e "${YELLOW}Services disponibles:${NC}"
kubectl get services -n voting-app
echo ""

# Obtener URLs de acceso
MINIKUBE_IP=$(minikube ip)
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}🎉 ¡Despliegue completado exitosamente!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}🗳️  Vote App:${NC} http://${MINIKUBE_IP}:30080"
echo -e "${GREEN}📊 Result App:${NC} http://${MINIKUBE_IP}:30081"
echo ""
echo -e "${YELLOW}Para acceder más fácil, puedes usar:${NC}"
echo -e "  minikube service vote-service -n voting-app"
echo -e "  minikube service result-service -n voting-app"
echo ""
echo -e "${YELLOW}Para ver los logs:${NC}"
echo -e "  kubectl logs -f deployment/vote -n voting-app"
echo -e "  kubectl logs -f deployment/worker -n voting-app"
echo -e "  kubectl logs -f deployment/result -n voting-app"
echo ""
echo -e "${YELLOW}Para eliminar todo:${NC}"
echo -e "  kubectl delete namespace voting-app"
echo ""
