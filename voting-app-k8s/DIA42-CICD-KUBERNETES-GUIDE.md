# 🚀 Día 42 - Desafío Final Semana 6: CI/CD con Kubernetes

## 🎯 Objetivo

Desplegar la **Roxs Voting App** en Kubernetes usando CI/CD con GitHub Actions, múltiples ambientes, health checks y rollback automático.

---

## 📁 Estructura del Proyecto

```
voting-app-k8s/
├── base/                          # Manifiestos base de Kubernetes
│   ├── kustomization.yaml        # Configuración base de Kustomize
│   ├── namespace.yaml
│   ├── storage.yaml
│   ├── configs-secrets.yaml
│   ├── postgres.yaml
│   ├── redis.yaml
│   ├── vote.yaml
│   ├── worker.yaml
│   └── result.yaml
│
└── overlays/                      # Configuraciones por ambiente
    ├── dev/
    │   └── kustomization.yaml    # Imágenes: *:staging, NodePort: 31000-31001
    ├── staging/
    │   └── kustomization.yaml    # Imágenes: *:staging, NodePort: 32000-32001
    └── prod/
        └── kustomization.yaml    # Imágenes: *:production, NodePort: 33000-33001
                                   # 3 replicas para vote/result, 2 para worker

.github/workflows/
├── ci.yml                         # Tests + Build & Push de imágenes Docker
├── deploy-k8s-dev.yml            # Deploy automático a Dev (develop branch)
├── deploy-k8s-staging.yml        # Deploy automático a Staging (post-dev)
└── deploy-k8s-prod.yml           # Deploy manual a Prod (requiere aprobación)
```

---

## 🔧 Configuración Paso a Paso

### 1️⃣ Preparar tu Clúster de Kubernetes

Puedes usar **Minikube**, **Kind**, **K3s**, o cualquier clúster de Kubernetes.

#### Opción A: Minikube (Local)
```bash
# Iniciar Minikube
minikube start --driver=docker --cpus=4 --memory=8192

# Verificar
kubectl cluster-info
kubectl get nodes
```

#### Opción B: Kind (Local)
```bash
# Crear clúster
kind create cluster --name voting-app

# Verificar
kubectl cluster-info
kubectl get nodes
```

#### Opción C: Clúster Cloud (GKE, EKS, AKS)
```bash
# Conectar a tu clúster
# GKE ejemplo:
gcloud container clusters get-credentials my-cluster --region us-central1

# Verificar
kubectl config current-context
kubectl get nodes
```

---

### 2️⃣ Configurar Secretos en GitHub

Ve a tu repositorio → **Settings** → **Secrets and variables** → **Actions**

#### Secretos Requeridos:

1. **KUBECONFIG_DEV** (Base64 del kubeconfig para Dev)
2. **KUBECONFIG_STAGING** (Base64 del kubeconfig para Staging)
3. **KUBECONFIG_PROD** (Base64 del kubeconfig para Prod)

#### Cómo obtener el kubeconfig en Base64:

```bash
# Para un solo clúster (usa el mismo para dev/staging/prod en ambiente local)
cat ~/.kube/config | base64 | tr -d '\n'

# Para clústeres separados, primero cambia el contexto
kubectl config use-context dev-cluster
cat ~/.kube/config | base64 | tr -d '\n'
```

##### ⚠️ IMPORTANTE para Minikube:

Si usas Minikube, el kubeconfig por defecto usa `127.0.0.1` que NO funcionará en GitHub Actions. Necesitas exponer el API server:

```bash
# Opción 1: Usar IP del nodo en lugar de localhost
minikube ip
# Edita ~/.kube/config y reemplaza https://127.0.0.1:xxxxx con https://<MINIKUBE_IP>:xxxxx

# Opción 2: Usar tunneling o runners self-hosted
# (más complejo pero más realista)
```

##### 💡 Recomendación para este desafío:

Para completar el desafío rápidamente, usa un clúster cloud (GKE trial, EKS, o K3s en una VM) o configura **self-hosted runners** con acceso a tu Minikube local.

---

### 3️⃣ Configurar Ambientes en GitHub

Ve a **Settings** → **Environments** y crea:

#### 🟢 Environment: `dev`
- Sin restricciones
- Deploy automático en cada push a `develop`

#### 🟡 Environment: `staging`
- Opción 1: Sin restricciones (auto)
- Opción 2: Con reviewers requeridos

#### 🔴 Environment: `production`
- **Required reviewers**: Agrega tu usuario
- **Wait timer**: 5 minutos (opcional)
- Deploy manual requerido

---

### 4️⃣ Actualizar las Referencias de Imágenes

Antes de hacer push, actualiza `GITHUB_USER` en los archivos de Kustomize:

```bash
# Reemplaza GITHUB_USER con tu username de GitHub
cd voting-app-k8s/overlays
find . -name "kustomization.yaml" -exec sed -i '' 's/GITHUB_USER/<TU_USUARIO_GITHUB>/g' {} +

# Verifica
grep "ghcr.io" */kustomization.yaml
```

O déjalo como está - el workflow lo reemplazará automáticamente con `${{ github.repository_owner }}`.

---

## 🚦 Flujo de CI/CD

### Flujo Completo

```
1. Push a develop
   ↓
2. CI Workflow (tests + build images)
   ↓
3. Tag images: *:staging + *:<SHA>
   ↓
4. Deploy to Dev (automático)
   ↓
5. Health checks en Dev
   ↓
6. Deploy to Staging (automático)
   ↓
7. Health checks en Staging
   ↓
8. (ESPERA) Aprobación manual
   ↓
9. Deploy to Production
   ↓
10. Health checks exhaustivos
    ↓
11. ✅ Success o ❌ Rollback automático
```

### Para Deploy a Producción (rama main)

```
1. Merge develop → main
   ↓
2. CI Workflow (tests + build images)
   ↓
3. Tag images: *:production + *:latest + *:<SHA>
   ↓
4. Manual Trigger a Production Workflow
   ↓
5. Requiere aprobación en GitHub UI
   ↓
6. Deploy + Health Checks + Smoke Tests
   ↓
7. ✅ Success o ❌ Rollback automático
```

---

## ✅ Health Checks Implementados

### 🔍 En todos los niveles:

1. **Kubernetes Liveness/Readiness Probes**
   - Vote: HTTP GET `/` en puerto 80
   - Result: HTTP GET `/` en puerto 3000
   - Worker: No necesita (backend)
   - PostgreSQL: `pg_isready` command
   - Redis: TCP check en puerto 6379

2. **GitHub Actions Checks**
   - `kubectl rollout status` con timeout
   - `kubectl wait --for=condition=ready pod`
   - Verificación de pods en estado Running
   - Curl tests desde dentro de los pods
   - Conteo de restarts
   - Análisis de logs para errores

3. **Rollback Automático**
   - Si cualquier check falla → `kubectl rollout undo`
   - Espera a que el rollback complete
   - Verifica que el estado anterior está healthy
   - Falla el workflow con mensaje claro

---

## 🧪 Pruebas Locales

### Probar Kustomize antes de hacer push:

```bash
# Ver manifiestos generados para Dev
kubectl kustomize voting-app-k8s/overlays/dev

# Ver manifiestos para Staging
kubectl kustomize voting-app-k8s/overlays/staging

# Ver manifiestos para Prod
kubectl kustomize voting-app-k8s/overlays/prod

# Aplicar a Dev (manualmente)
kubectl apply -k voting-app-k8s/overlays/dev

# Verificar
kubectl get all -n voting-app-dev

# Ver los pods
kubectl get pods -n voting-app-dev -w

# Probar la app
kubectl port-forward -n voting-app-dev svc/vote-service-dev 8080:80
# Abre http://localhost:8080 en el navegador

# Limpiar
kubectl delete -k voting-app-k8s/overlays/dev
```

---

## 📊 Verificación de Deployment

### Ver el estado de los deployments:

```bash
# Dev
kubectl get all -n voting-app-dev
kubectl get pods -n voting-app-dev -o wide

# Staging
kubectl get all -n voting-app-staging
kubectl logs -n voting-app-staging -l app=worker --tail=50

# Production
kubectl get all -n voting-app-prod
kubectl describe pod -n voting-app-prod -l app=vote
```

### Acceder a las aplicaciones:

#### Con Minikube:
```bash
# Dev
minikube service vote-service-dev -n voting-app-dev
minikube service result-service-dev -n voting-app-dev

# Staging
minikube service vote-service-staging -n voting-app-staging
minikube service result-service-staging -n voting-app-staging

# Production
minikube service vote-service-prod -n voting-app-prod
minikube service result-service-prod -n voting-app-prod
```

#### Con Load Balancer o NodePort directo:
```bash
# Obtener NodePort
kubectl get svc -n voting-app-dev

# Acceder con IP del nodo
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
echo "Vote: http://$NODE_IP:31000"
echo "Result: http://$NODE_IP:31001"
```

---

## 🐛 Troubleshooting

### Problema: Imágenes no se pueden pull

```bash
# Verificar que las imágenes existen en GHCR
curl -H "Authorization: token GITHUB_TOKEN" \
  https://ghcr.io/v2/<USUARIO>/roxs-devops-project90-vote/tags/list

# Crear ImagePullSecret si es necesario
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=<USUARIO> \
  --docker-password=<GITHUB_TOKEN> \
  -n voting-app-dev

# Agregar al deployment
# spec.template.spec.imagePullSecrets:
#   - name: ghcr-secret
```

### Problema: Pods en CrashLoopBackOff

```bash
# Ver logs
kubectl logs -n voting-app-dev <pod-name>

# Ver eventos
kubectl describe pod -n voting-app-dev <pod-name>

# Verificar variables de entorno
kubectl exec -n voting-app-dev <pod-name> -- env
```

### Problema: Rollout atascado

```bash
# Ver historial de rollouts
kubectl rollout history deployment/vote-dev -n voting-app-dev

# Rollback manual
kubectl rollout undo deployment/vote-dev -n voting-app-dev

# Rollback a revisión específica
kubectl rollout undo deployment/vote-dev -n voting-app-dev --to-revision=2
```

### Problema: Workflow falla en "Configure kubeconfig"

Verifica que:
1. El secreto `KUBECONFIG_DEV` está creado en GitHub
2. El valor está en Base64 correcto: `cat ~/.kube/config | base64 -w 0`
3. El API server es accesible desde GitHub Actions (no `127.0.0.1` para Minikube)

---

## 🎓 Checklist de Validación

Antes de considerar el desafío completado, verifica:

- [ ] ✅ Manifiestos de K8s creados con Kustomize (base + overlays)
- [ ] ✅ 3 ambientes funcionando: dev, staging, prod
- [ ] ✅ Namespaces separados: `voting-app-dev`, `voting-app-staging`, `voting-app-prod`
- [ ] ✅ Workflow CI ejecuta tests y construye imágenes Docker
- [ ] ✅ Deploy automático a Dev en push a `develop`
- [ ] ✅ Deploy automático a Staging después de Dev exitoso
- [ ] ✅ Deploy a Prod requiere aprobación manual
- [ ] ✅ Health checks configurados en todos los deployments
- [ ] ✅ Readiness/Liveness probes funcionando
- [ ] ✅ Rollback automático implementado en workflows
- [ ] ✅ Tested rollback manualmente (simula un error)
- [ ] ✅ Pods accesibles vía NodePort o LoadBalancer
- [ ] ✅ Votos se guardan correctamente en PostgreSQL
- [ ] ✅ Worker procesa votos de Redis a PostgreSQL
- [ ] ✅ Result muestra votos actualizados en tiempo real
- [ ] ✅ Documentación completa (este archivo)

---

## 🎉 ¡Felicitaciones!

Si completaste todos los puntos anteriores, **HAS COMPLETADO EL DÍA 42** 🎊

### 🏆 Lo que lograste:

✅ CI/CD completo con GitHub Actions  
✅ Múltiples ambientes en Kubernetes  
✅ Health checks robustos  
✅ Rollback automático en fallos  
✅ Infraestructura como código con Kustomize  
✅ Separación de concerns (base + overlays)  
✅ Seguridad (secrets, namespaces aislados)  
✅ Observabilidad (logs, eventos, métricas)

### 📸 Comparte tu éxito

1. Toma screenshots de:
   - GitHub Actions mostrando pipelines exitosos
   - Aplicación desplegada en los 3 ambientes
   - `kubectl get all -n voting-app-prod`
   - Navegador mostrando la voting app funcionando

2. Comparte en redes con **#DevOpsConRoxs #90DaysDevOps**

3. Cuenta lo que más te costó y cómo lo resolviste

---

## 📚 Recursos Adicionales

- [Kustomize Documentation](https://kustomize.io/)
- [Kubernetes Health Checks](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [GitHub Actions Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

## 🚀 Próximos Pasos (Opcional - Mejoras avanzadas)

Si quieres ir más allá:

1. **Agregar Helm en lugar de Kustomize**
   - Más flexible para templating
   - Values por ambiente

2. **Implementar GitOps con ArgoCD o FluxCD**
   - Sync automático desde Git
   - UI para visualizar estado

3. **Agregar Ingress en lugar de NodePort**
   - URLs amigables
   - TLS/SSL

4. **Implementar HorizontalPodAutoscaler**
   - Escalado automático basado en CPU/memoria

5. **Agregar Monitoring con Prometheus + Grafana**
   - Métricas en tiempo real
   - Alertas

6. **Implementar Backup automático de PostgreSQL**
   - CronJobs en K8s
   - Backup a S3 o similar

---

**Autor:** Nicolas Herrera  
**Fecha:** 30 de Marzo de 2026  
**Challenge:** #90DaysDevOps Día 42 - Semana 6  
**GitHub:** [roxsross/roxs-devops-project90](https://github.com/roxsross/roxs-devops-project90)
