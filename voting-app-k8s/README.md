# 🚀 Roxs Voting App - Kubernetes Deployments

Este directorio contiene manifiestos de Kubernetes para desplegar la **Roxs Voting App** con soporte para **múltiples ambientes**.

## 🎯 Dos Modos de Despliegue

### 1️⃣ **Día 35** - Despliegue Local Básico 
Manifiestos numerados `01-*.yaml` hasta `08-*.yaml` para despliegue local en Minikube.

### 2️⃣ **Día 42** - CI/CD con Múltiples Ambientes
Estructura con Kustomize (`base/` + `overlays/`) para CI/CD con GitHub Actions.

---

## 📁 Estructura del Directorio

```
voting-app-k8s/
├── 01-namespace.yaml          # [Día 35] Namespace base
├── 02-storage.yaml            # [Día 35] PVC para PostgreSQL
├── 03-configs-secrets.yaml    # [Día 35] ConfigMaps y Secrets
├── 04-postgres.yaml           # [Día 35] PostgreSQL deployment
├── 05-redis.yaml              # [Día 35] Redis deployment
├── 06-vote.yaml               # [Día 35] Vote app deployment
├── 07-worker.yaml             # [Día 35] Worker deployment
├── 08-result.yaml             # [Día 35] Result app deployment
├── deploy.sh                  # [Día 35] Script de despliegue local
│
├── base/                      # [Día 42] Manifiestos base de Kustomize
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── storage.yaml
│   ├── configs-secrets.yaml
│   ├── postgres.yaml
│   ├── redis.yaml
│   ├── vote.yaml
│   ├── worker.yaml
│   └── result.yaml
│
├── overlays/                  # [Día 42] Configuraciones por ambiente
│   ├── dev/
│   │   └── kustomization.yaml # Dev: images:*:staging, NodePort:31000-31001
│   ├── staging/
│   │   └── kustomization.yaml # Staging: images:*:staging, NodePort:32000-32001
│   └── prod/
│       └── kustomization.yaml # Prod: images:*:production, NodePort:33000-33001
│                               #       3 replicas, más recursos
│
├── quick-start-k8s.sh         # [Día 42] Script de despliegue multi-ambiente
├── DIA42-CICD-KUBERNETES-GUIDE.md  # [Día 42] Guía completa CI/CD
├── DEPLOYMENT_SUMMARY.md      # [Día 35] Resumen del despliegue básico
└── README.md                  # Este archivo
```

---

## 🚀 Guías Rápidas

### Para Día 35 - Despliegue Local

```bash
# Iniciar Minikube
minikube start

# Opción 1: Usar script automatizado
chmod +x deploy.sh
./deploy.sh

# Opción 2: Aplicar manualmente
kubectl apply -f 01-namespace.yaml
kubectl apply -f 02-storage.yaml
kubectl apply -f 03-configs-secrets.yaml
kubectl apply -f 04-postgres.yaml
kubectl apply -f 05-redis.yaml
kubectl apply -f 06-vote.yaml
kubectl apply -f 07-worker.yaml
kubectl apply -f 08-result.yaml

# Verificar
kubectl get pods -n voting-app

# Acceder a la app
minikube service vote-service -n voting-app
minikube service result-service -n voting-app
```

📖 **Documentación completa**: Ver [DEPLOYMENT_SUMMARY.md](./DEPLOYMENT_SUMMARY.md)

---

### Para Día 42 - CI/CD con Múltiples Ambientes

```bash
# Opción 1: Despliegue local para testing
chmod +x quick-start-k8s.sh
./quick-start-k8s.sh local

# Opción 2: Despliegue con Kustomize
kubectl apply -k overlays/dev        # Deploy a Dev
kubectl apply -k overlays/staging    # Deploy a Staging
kubectl apply -k overlays/prod       # Deploy a Prod

# Verificar
kubectl get all -n voting-app-dev
kubectl get all -n voting-app-staging
kubectl get all -n voting-app-prod

# Acceder (ejemplo para dev)
minikube service vote-service-dev -n voting-app-dev
minikube service result-service-dev -n voting-app-dev
```

📖 **Documentación completa**: Ver [DIA42-CICD-KUBERNETES-GUIDE.md](./DIA42-CICD-KUBERNETES-GUIDE.md)

---

## 🏗️ Arquitectura de la Aplicación

```
┌─────────────┐
│   Usuario   │
└──────┬──────┘
       │
       ├──────────> Vote App (Flask)
       │              ↓
       │            Redis (Cache)
       │              ↓
       │            Worker (Node.js)
       │              ↓
       │            PostgreSQL (Database)
       │              ↓
       └──────────> Result App (Node.js)
```

### Componentes:

| Componente | Imagen | Puerto | Réplicas | Descripción |
|------------|--------|--------|----------|-------------|
| **vote** | vote:local o ghcr.io/*/vote | 80 | 2-3 | Frontend de votación (Flask) |
| **worker** | worker:local o ghcr.io/*/worker | - | 1-2 | Procesa votos Redis→PostgreSQL |
| **result** | result:local o ghcr.io/*/result | 3000 | 2-3 | Dashboard de resultados (Node.js) |
| **redis** | redis:alpine | 6379 | 1 | Cache de votos |
| **postgres** | postgres:15-alpine | 5432 | 1 | Base de datos persistente |

---

## 🔍 Comandos Útiles

### Ver estado de los recursos

```bash
# Ver todos los pods
kubectl get pods -n voting-app         # Día 35
kubectl get pods -n voting-app-dev     # Día 42 - Dev
kubectl get pods -n voting-app-staging # Día 42 - Staging
kubectl get pods -n voting-app-prod    # Día 42 - Prod

# Ver servicios
kubectl get svc -n voting-app

# Ver deployments
kubectl get deployments -n voting-app
```

### Debugging

```bash
# Ver logs de un componente
kubectl logs -l app=vote -n voting-app --tail=50 -f
kubectl logs -l app=worker -n voting-app --tail=50 -f
kubectl logs -l app=result -n voting-app --tail=50 -f

# Ver eventos
kubectl get events -n voting-app --sort-by='.lastTimestamp' | tail -20

# Describir un pod (para ver errores)
kubectl describe pod <POD_NAME> -n voting-app

# Entrar a un pod
kubectl exec -it <POD_NAME> -n voting-app -- /bin/sh

# Ver configuración de un deployment
kubectl get deployment vote -n voting-app -o yaml
```

### Gestión de Deployments

```bash
# Reiniciar un deployment
kubectl rollout restart deployment/vote -n voting-app

# Ver historial de rollouts
kubectl rollout history deployment/vote -n voting-app

# Rollback al deployment anterior
kubectl rollout undo deployment/vote -n voting-app

# Rollback a una revisión específica
kubectl rollout undo deployment/vote -n voting-app --to-revision=2

# Escalar manualmente
kubectl scale deployment/vote --replicas=3 -n voting-app
```

### Limpieza

```bash
# Eliminar todo (Día 35)
kubectl delete namespace voting-app

# Eliminar por ambiente (Día 42)
kubectl delete namespace voting-app-dev
kubectl delete namespace voting-app-staging
kubectl delete namespace voting-app-prod

# Eliminar usando Kustomize
kubectl delete -k overlays/dev
kubectl delete -k overlays/staging
kubectl delete -k overlays/prod
```

---

## 🌐 Acceso a las Aplicaciones

### Minikube

```bash
# Obtener IP de Minikube
minikube ip

# Abrir servicios automáticamente
minikube service vote-service -n voting-app
minikube service result-service -n voting-app

# Listartodos los servicios
minikube service list
```

### Port-Forward (alternativa)

```bash
# Vote App
kubectl port-forward -n voting-app svc/vote-service 8080:80

# Result App
kubectl port-forward -n voting-app svc/result-service 8081:3000

# Accede en: http://localhost:8080 y http://localhost:8081
```

### NodePort (producción)

```bash
# Obtener NodePorts
kubectl get svc -n voting-app

# Acceder con IP del nodo
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
echo "Vote:   http://$NODE_IP:31000"
echo "Result: http://$NODE_IP:31001"
```

---

## 🎓 Recursos de Aprendizaje

### Día 35 - Conceptos Aprendidos
- ✅ Namespaces
- ✅ Deployments y ReplicaSets
- ✅ Services (ClusterIP, NodePort)
- ✅ ConfigMaps y Secrets
- ✅ PersistentVolumes y PersistentVolumeClaims
- ✅ Liveness y Readiness Probes
- ✅ Resource Limits y Requests
- ✅ Labels y Selectors

### Día 42 - Conceptos Aprendidos
- ✅ Kustomize (base + overlays)
- ✅ GitHub Actions CI/CD
- ✅ Múltiples ambientes (dev, staging, prod)
- ✅ Health checks avanzados
- ✅ Rollback automático
- ✅ GitHub Environments con aprobaciones
- ✅ GHCR (GitHub Container Registry)
- ✅ Infrastructure as Code

---

## 🆘 Troubleshooting

### Pods en estado CrashLoopBackOff

```bash
# Ver logs del pod
kubectl logs <POD_NAME> -n voting-app

# Ver eventos del pod
kubectl describe pod <POD_NAME> -n voting-app

# Verificar probes (puede ser timeout muy corto)
kubectl get pod <POD_NAME> -n voting-app -o yaml | grep -A 10 "livenessProbe\|readinessProbe"
```

### ImagePullBackOff

```bash
# Verificar el nombre de la imagen
kubectl get pod <POD_NAME> -n voting-app -o yaml | grep image:

# Para imágenes de GHCR, crear secret
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=<USUARIO> \
  --docker-password=<GITHUB_TOKEN> \
  -n voting-app

# Agregar secret al deployment (spec.template.spec.imagePullSecrets)
```

### Pods no pueden conectarse entre sí

```bash
# Verificar servicios
kubectl get svc -n voting-app

# Probar DNS interno
kubectl run -it --rm debug --image=busybox --restart=Never -n voting-app -- nslookup redis-service

# Verificar network policies (si aplica)
kubectl get networkpolicies -n voting-app
```

---

## 📚 Documentación Adicional

- 📄 [DEPLOYMENT_SUMMARY.md](./DEPLOYMENT_SUMMARY.md) - Resumen detallado del Día 35
- 📄 [DIA42-CICD-KUBERNETES-GUIDE.md](./DIA42-CICD-KUBERNETES-GUIDE.md) - Guía completa CI/CD con GitHub Actions
- 🔗 [Kubernetes Documentation](https://kubernetes.io/docs/)
- 🔗 [Kustomize Documentation](https://kustomize.io/)
- 🔗 [GitHub Actions Documentation](https://docs.github.com/actions)

---

**Autor:** Nicolas Herrera  
**Challenges:** Día 35 + Día 42 - 90 Days DevOps con Roxs  
**Fecha:** Marzo 2026  
**Proyecto:** [roxsross/roxs-devops-project90](https://github.com/roxsross/roxs-devops-project90)
