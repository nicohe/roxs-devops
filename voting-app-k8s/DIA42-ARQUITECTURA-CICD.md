# 🚀 Arquitectura CI/CD - Día 42

## 📊 Vista General del Sistema

```
┌─────────────────────────────────────────────────────────────────────┐
│                         GITHUB REPOSITORY                           │
│                                                                       │
│  Branch: develop              Branch: main                          │
│     │                             │                                  │
└─────┼─────────────────────────────┼──────────────────────────────────┘
      │                             │
      ▼                             ▼
┌─────────────────────┐   ┌─────────────────────┐
│   CI Workflow       │   │   CI Workflow       │
│   ===============   │   │   ===============   │
│   • Tests          │   │   • Tests           │
│   • Build Images   │   │   • Build Images    │
│   • Push to GHCR   │   │   • Push to GHCR    │
│   Tag: staging     │   │   Tag: production   │
└──────────┬──────────┘   └──────────┬──────────┘
           │                         │
           ▼                         │
┌─────────────────────┐             │
│  Deploy K8s - Dev   │             │
│  ===============    │             │
│  • Apply -k dev     │             │
│  • Health Checks    │             │
│  • Auto Rollback    │             │
└──────────┬──────────┘             │
           │                         │
           ▼                         │
┌─────────────────────┐             │
│ Deploy K8s - Staging│             │
│ =================== │             │
│ • Apply -k staging  │             │
│ • Health Checks     │             │
│ • Smoke Tests       │             │
│ • Auto Rollback     │             │
└──────────┬──────────┘             │
           │                         │
           │    ┌────────────────────┘
           │    │
           │    │  ⚠️ MANUAL TRIGGER + APPROVAL
           │    │
           ▼    ▼
    ┌─────────────────────┐
    │Deploy K8s - Prod    │
    │==================== │
    │• Require Approval   │
    │• Backup            │
    │• kubectl diff      │
    │• Apply -k prod     │
    │• Health Checks     │
    │• Smoke Tests       │
    │• Log Analysis      │
    │• Auto Rollback     │
    └─────────┬───────────┘
              │
              ▼
    ┌─────────────────────┐
    │  PRODUCTION LIVE    │
    │  ✅ SUCCESS!        │
    └─────────────────────┘
```

---

## 🎯 Ambientes Kubernetes

```
┌──────────────────────────────────────────────────────────────────┐
│                      KUBERNETES CLUSTER                          │
├──────────────────────────────────────────────────────────────────┤
│                                                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Namespace: voting-app-dev                                 │ │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │ │
│  │  🐳 vote:staging (×2)              NodePort: 31000        │ │
│  │  🐳 result:staging (×2)            NodePort: 31001        │ │
│  │  🐳 worker:staging (×1)                                   │ │
│  │  🐳 postgres:15-alpine (×1)                               │ │
│  │  🐳 redis:alpine (×1)                                     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Namespace: voting-app-staging                             │ │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │ │
│  │  🐳 vote:staging (×2)              NodePort: 32000        │ │
│  │  🐳 result:staging (×2)            NodePort: 32001        │ │
│  │  🐳 worker:staging (×1)                                   │ │
│  │  🐳 postgres:15-alpine (×1)                               │ │
│  │  🐳 redis:alpine (×1)                                     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Namespace: voting-app-prod                    🔒 PROTECTED│ │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │ │
│  │  🐳 vote:production (×3)           NodePort: 33000        │ │
│  │  🐳 result:production (×3)         NodePort: 33001        │ │
│  │  🐳 worker:production (×2)                                │ │
│  │  🐳 postgres:15-alpine (×1)        + PVC 1Gi              │ │
│  │  🐳 redis:alpine (×1)                                     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                    │
└──────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Flujo de Datos de la Aplicación

```
┌─────────────┐
│   Usuario   │
└──────┬──────┘
       │
       │ HTTP GET/POST
       │
       ▼
┌──────────────────┐
│   Vote Service   │
│  (Flask Python)  │   ← Liveness/Readiness Probes
│   NodePort:      │
│   31000 (dev)    │
│   32000 (staging)│
│   33000 (prod)   │
└────────┬─────────┘
         │
         │ RPUSH vote
         ▼
┌──────────────────┐
│  Redis Service   │
│  (Cache/Queue)   │   ← TCP Health Check
│  ClusterIP:6379  │
└────────┬─────────┘
         │
         │ LPOP vote (polling)
         ▼
┌──────────────────┐
│ Worker (Node.js) │   ← Liveness Check (process)
│  (Background)    │
│  No Service      │
└────────┬─────────┘
         │
         │ INSERT vote
         ▼
┌──────────────────┐
│Postgres Service  │
│   (Database)     │   ← pg_isready Probe
│  ClusterIP:5432  │   ← PersistentVolume (1Gi)
└────────┬─────────┘
         │
         │ SELECT * FROM votes
         ▼
┌──────────────────┐
│  Result Service  │
│  (Node.js + WS)  │   ← Liveness/Readiness Probes
│   NodePort:      │
│   31001 (dev)    │
│   32001 (staging)│
│   33001 (prod)   │
└────────┬─────────┘
         │
         │ HTTP + WebSocket
         ▼
┌─────────────┐
│   Usuario   │
│ (Real-time) │
└─────────────┘
```

---

## 🛡️ Health Checks en Detalle

```
┌─────────────────────────────────────────────────────────────┐
│              HEALTH CHECK LAYERS                            │
└─────────────────────────────────────────────────────────────┘

Layer 1: Kubernetes Probes (Manifiestos)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
├─ Vote Pod
│  ├─ livenessProbe:  HTTP GET / :80 (every 10s)
│  └─ readinessProbe: HTTP GET / :80 (every 5s)
├─ Result Pod  
│  ├─ livenessProbe:  HTTP GET / :3000 (every 10s)
│  └─ readinessProbe: HTTP GET / :3000 (every 5s)
├─ Worker Pod
│  └─ (No probes - backend service)
├─ PostgreSQL Pod
│  ├─ livenessProbe:  EXEC pg_isready (every 10s)
│  └─ readinessProbe: EXEC pg_isready (every 5s)
└─ Redis Pod
   ├─ livenessProbe:  TCP :6379 (every 10s)
   └─ readinessProbe: TCP :6379 (every 5s)

Layer 2: Deployment Status (GitHub Actions)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
├─ kubectl rollout status deployment/vote-<env>
├─ kubectl rollout status deployment/result-<env>
├─ kubectl rollout status deployment/worker-<env>
├─ kubectl rollout status deployment/postgres-<env>
└─ kubectl rollout status deployment/redis-<env>
   └─ Timeout: 5 minutos c/u

Layer 3: Pod Readiness (GitHub Actions)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
├─ kubectl wait --for=condition=ready pod -l app=vote
├─ kubectl wait --for=condition=ready pod -l app=result
└─ Timeout: 2-3 minutos

Layer 4: Application Health (Staging/Prod only)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
├─ kubectl exec <pod> -- curl -f http://localhost
├─ Verificar pods NO en estado Running
├─ Análisis de restarts (conteo)
└─ Análisis de logs (grep -i "error")

Layer 5: Smoke Tests (Production only)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
├─ Verificar 0 pods NOT Running
├─ Conteo total de restarts
├─ Análisis exhaustivo de logs (últimas 50 líneas)
└─ Revisión de eventos recientes
```

---

## 🔙 Rollback Automático

```
┌─────────────────────────────────────────────────────────┐
│            ROLLBACK STRATEGY                            │
└─────────────────────────────────────────────────────────┘

Trigger: Cualquier check falla
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 1: Detección de Fallo
  ├─ Health check failed
  ├─ Deployment timeout
  ├─ Probe failures
  └─ Smoke test failed

        ↓

Step 2: Rollback Execution
  ├─ kubectl rollout undo deployment/vote-<env>
  ├─ kubectl rollout undo deployment/result-<env>
  └─ kubectl rollout undo deployment/worker-<env>

        ↓

Step 3: Wait for Rollback Complete
  ├─ kubectl rollout status (timeout 3-5m)
  └─ Esperar que todos completen

        ↓

Step 4: Verify Rollback Health (Prod only)
  ├─ kubectl wait --for=condition=ready pod
  └─ Verificar que versión anterior está healthy

        ↓

Step 5: Fail Workflow
  ├─ Exit 1
  ├─ Mensaje claro en GitHub Actions
  └─ Notificación (si configurada)

        ↓

Step 6: Manual Investigation
  ├─ Review logs: kubectl logs <pod>
  ├─ Review events: kubectl get events
  └─ Fix issue & retry deployment
```

---

## 📂 Estructura de Kustomize

```
voting-app-k8s/
│
├── base/                          ← Common manifests
│   ├── kustomization.yaml         ← Base config
│   ├── namespace.yaml
│   ├── storage.yaml
│   ├── configs-secrets.yaml
│   ├── postgres.yaml
│   ├── redis.yaml
│   ├── vote.yaml                  ← image: vote-image
│   ├── worker.yaml                ← image: worker-image
│   └── result.yaml                ← image: result-image
│
└── overlays/                      ← Environment-specific
    ├── dev/
    │   └── kustomization.yaml     ← Dev overrides
    │       ├─ bases: ../../base
    │       ├─ namespace: voting-app-dev
    │       ├─ nameSuffix: -dev
    │       ├─ images:
    │       │  ├─ vote-image → ghcr.io/user/vote:staging
    │       │  ├─ worker-image → ghcr.io/user/worker:staging
    │       │  └─ result-image → ghcr.io/user/result:staging
    │       └─ patches:
    │          └─ namespace name → voting-app-dev
    │
    ├── staging/
    │   └── kustomization.yaml     ← Staging overrides
    │       ├─ bases: ../../base
    │       ├─ namespace: voting-app-staging
    │       ├─ nameSuffix: -staging
    │       ├─ images: (same as dev)
    │       └─ patches:
    │          ├─ namespace name → voting-app-staging
    │          ├─ vote NodePort → 32000
    │          └─ result NodePort → 32001
    │
    └── prod/
        └── kustomization.yaml     ← Prod overrides
            ├─ bases: ../../base
            ├─ namespace: voting-app-prod
            ├─ nameSuffix: -prod
            ├─ images:
            │  ├─ vote-image → ghcr.io/user/vote:production
            │  ├─ worker-image → ghcr.io/user/worker:production
            │  └─ result-image → ghcr.io/user/result:production
            ├─ replicas:
            │  ├─ vote: 3
            │  ├─ result: 3
            │  └─ worker: 2
            └─ patches:
               ├─ namespace name → voting-app-prod
               ├─ vote NodePort → 33000
               ├─ result NodePort → 33001
               └─ increased resources (memory/cpu)
```

---

## 🔐 Secrets Management

```
GitHub Repository Secrets
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
├─ KUBECONFIG_DEV
│  └─ Base64 del kubeconfig para Dev cluster
├─ KUBECONFIG_STAGING
│  └─ Base64 del kubeconfig para Staging cluster
└─ KUBECONFIG_PROD
   └─ Base64 del kubeconfig para Prod cluster

GitHub Environment Protection
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
├─ dev
│  └─ No protection (auto deploy)
├─ staging
│  └─ Optional: Required reviewers
└─ production
   ├─ Required reviewers: 1+
   ├─ Wait timer: 5 minutes
   └─ Manual confirmation required

Kubernetes Secrets (in cluster)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
└─ postgres-secret
   ├─ POSTGRES_USER: postgres
   └─ POSTGRES_PASSWORD: postgres123
   (Repeated in each namespace)
```

---

## 📈 Monitoring Points

```
┌─────────────────────────────────────────────────────────┐
│         WHERE TO MONITOR IN GITHUB ACTIONS              │
└─────────────────────────────────────────────────────────┘

✅ CI Workflow
   ├─ Unit tests pass?
   ├─ Integration tests pass?
   └─ Images built and pushed?

✅ Deploy Dev Workflow
   ├─ Rollout status OK?
   ├─ All pods ready?
   └─ Health checks pass?

✅ Deploy Staging Workflow
   ├─ All Dev checks +
   ├─ Smoke tests pass?
   └─ No errors in logs?

✅ Deploy Production Workflow
   ├─ All Staging checks +
   ├─ Manual approval given?
   ├─ Backup created?
   ├─ Smoke tests pass?
   ├─ Log analysis clean?
   └─ Zero unexpected restarts?

┌─────────────────────────────────────────────────────────┐
│          WHERE TO MONITOR IN KUBERNETES                 │
└─────────────────────────────────────────────────────────┘

✅ Pod Level
   kubectl get pods -n <namespace>
   ├─ All in Running state?
   ├─ READY column shows x/x?
   └─ Low restart count?

✅ Deployment Level
   kubectl get deployments -n <namespace>
   ├─ READY shows x/x?
   └─ UP-TO-DATE matches READY?

✅ Service Level
   kubectl get svc -n <namespace>
   ├─ Services have endpoints?
   └─ NodePorts correct?

✅ Events
   kubectl get events -n <namespace>
   └─ No error/warning events?

✅ Logs
   kubectl logs -l app=<component> -n <namespace>
   └─ No unexpected errors?
```

---

## 🎯 Success Criteria

```
✅ Dev Deployment Success
   ├─ Pods: 7/7 Running
   ├─ Deployments: 5/5 Ready
   ├─ Health checks: All passing
   └─ Accessible: http://<node>:31000-31001

✅ Staging Deployment Success
   ├─ Pods: 7/7 Running
   ├─ Deployments: 5/5 Ready
   ├─ Health checks: All passing
   ├─ Smoke tests: Passed
   └─ Accessible: http://<node>:32000-32001

✅ Production Deployment Success
   ├─ Pods: 10/10 Running (more replicas)
   ├─ Deployments: 5/5 Ready
   ├─ Health checks: All passing
   ├─ Smoke tests: Passed
   ├─ Log analysis: Clean
   ├─ Zero unexpected restarts
   └─ Accessible: http://<node>:33000-33001
```

---

**Creado para:** Día 42 - 90 Days DevOps con Roxs  
**Fecha:** 30 de Marzo de 2026  
**Autor:** Nicolas Herrera
