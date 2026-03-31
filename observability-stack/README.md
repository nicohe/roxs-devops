# 🌟 Día 56 - Voting App con Observabilidad End-to-End

## 🎯 Objetivo del Desafío

Integrar el **Voting App** con un stack completo de observabilidad enterprise, demostrando los 3 pilares: **Métricas, Logs y Traces**.

---

## 🏗️ Arquitectura de Observabilidad

```
┌─────────────────────────────────────────────────────────────┐
│                    VOTING APP                                │
├──────────────┬──────────────┬──────────────┬────────────────┤
│   Vote UI    │   Worker     │  Result UI   │  Redis + PG    │
│   (Flask)    │  (Node.js)   │  (Node.js)   │  (Databases)   │
└──────┬───────┴──────┬───────┴──────┬───────┴────────┬────────┘
       │              │              │                │
       ├──────────────┴──────────────┴────────────────┤
       │          INSTRUMENTATION                     │
       ├──────────────┬──────────────┬────────────────┤
       │   Prometheus │    Jaeger    │   Filebeat     │
       │    Metrics   │    Traces    │     Logs       │
       └──────┬───────┴──────┬───────┴────────┬────────┘
              │              │                │
       ┌──────┴──────┐ ┌────┴────┐    ┌──────┴────────┐
       │  Prometheus │ │  Jaeger │    │ Elasticsearch │
       │             │ │   UI    │    │   + Kibana    │
       └──────┬──────┘ └─────────┘    └───────────────┘
              │
       ┌──────┴──────┐
       │   Grafana   │← Dashboards + Alerts
       └─────────────┘
```

---

## ✅ Pre-requisitos

### 1. Cluster Kubernetes Local
```bash
# Opción 1: kind (recomendado)
kind create cluster --name observability --config=kind-config.yaml

# Opción 2: minikube
minikube start --cpus 4 --memory 8192 --driver=docker

# Opción 3: Docker Desktop Kubernetes
# Habilitar Kubernetes en Docker Desktop settings
```

### 2. Stack de Observabilidad (Día 55)

Necesitas tener desplegado:
- ✅ Prometheus Stack (via Helm)
- ✅ Grafana
- ✅ Jaeger para tracing
- ✅ ELK Stack (Elasticsearch + Kibana) para logs

**Si NO tienes el stack desplegado**, ve primero al [Día 55](https://90daysdevops.295devops.com/semana-08/dia55)

---

## 📋 Checklist de Readiness

Antes de continuar, verifica:

```bash
# 1. Cluster corriendo
kubectl cluster-info

# 2. Prometheus operador instalado
kubectl get pods -n monitoring | grep prometheus-operator

# 3. Grafana corriendo
kubectl get pods -n monitoring | grep grafana

# 4. Jaeger instalado
kubectl get pods -n tracing | grep jaeger

# 5. ELK stack (si está configurado)
kubectl get pods -n logging | grep elastic
```

---

## 🚀 Despliegue Rápido

### Paso 1: Desplegar Voting App Instrumentada

```bash
# Aplicar todos los manifests de la app
kubectl apply -f kubernetes/01-namespace.yaml
kubectl apply -f kubernetes/02-databases.yaml
kubectl apply -f kubernetes/03-voting-app.yaml

# Verificar pods
kubectl get pods -n voting-app
```

### Paso 2: Conectar con Prometheus

```bash
# Aplicar ServiceMonitors
kubectl apply -f kubernetes/04-servicemonitors.yaml

# Verificar targets en Prometheus
# http://localhost:30090/targets (buscar "voting-app")
```

### Paso 3: Importar Dashboards

```bash
# Crear ConfigMaps con dashboards
kubectl create configmap voting-business-dashboard \
  --from-file=grafana-dashboards/business-dashboard.json \
  -n monitoring

kubectl create configmap voting-technical-dashboard \
  --from-file=grafana-dashboards/technical-dashboard.json \
  -n monitoring

# Label para auto-import
kubectl label configmap voting-business-dashboard grafana_dashboard=1 -n monitoring
kubectl label configmap voting-technical-dashboard grafana_dashboard=1 -n monitoring
```

### Paso 4: Configurar Alertas

```bash
# Aplicar PrometheusRules
kubectl apply -f prometheus-rules/voting-app-alerts.yaml

# Verificar alerts en Prometheus
# http://localhost:30090/alerts
```

### Paso 5: Load Testing

```bash
# Port-forward para acceder a la app
kubectl port-forward -n voting-app svc/vote 30080:80 &
kubectl port-forward -n voting-app svc/result 30081:80 &

# Ejecutar load test
chmod +x scripts/load-test-demo.sh
./scripts/load-test-demo.sh
```

---

## 📊 Acceso a Herramientas

Una vez desplegado, accede a:

| Herramienta | URL | Credenciales |
|-------------|-----|--------------|
| **Grafana** | http://localhost:30091 | admin / admin123 |
| **Prometheus** | http://localhost:30090 | - |
| **Jaeger UI** | http://localhost:16686 | - |
| **Kibana** | http://localhost:30093 | - |
| **Vote UI** | http://localhost:30080 | - |
| **Result UI** | http://localhost:30081 | - |

**Nota**: Los puertos pueden variar según tu configuración del Día 55.

---

## 📈 Estructura del Proyecto

```
observability-stack/
├── README.md                          # Este archivo
├── DIA56-GUIDE.md                     # Guía detallada paso a paso
├── DIA56-DEMO-SCRIPT.md               # Script para demo de 5 min
│
├── kubernetes/
│   ├── 01-namespace.yaml              # Namespace voting-app
│   ├── 02-databases.yaml              # Redis + PostgreSQL
│   ├── 03-voting-app.yaml             # Vote, Worker, Result
│   ├── 04-servicemonitors.yaml        # ServiceMonitors para Prometheus
│   └── kind-config.yaml               # Config para kind cluster
│
├── grafana-dashboards/
│   ├── business-dashboard.json        # KPIs de negocio
│   └── technical-dashboard.json       # Métricas técnicas SRE
│
├── prometheus-rules/
│   └── voting-app-alerts.yaml         # Alertas basadas en SLOs
│
└── scripts/
    ├── load-test-demo.sh              # Script de carga para demo
    ├── setup-observability.sh         # Setup completo automatizado
    └── verify-stack.sh                # Verificar que todo funciona
```

---

## 🎯 Métricas Clave Monitoreadas

### Business Metrics (Dashboards Ejecutivos)
- **Total de votos** (hoy, última hora, etc)
- **Votos por opción** (Cats vs Dogs)
- **Tasa de votación** (votes/min)
- **Usuarios activos** simultáneos

### Technical Metrics (SRE/DevOps)
- **Request Rate** (RPS por servicio)
- **Response Time** (P50, P95, P99)
- **Error Rate** (%) 
- **Queue Length** (votos pendientes en Redis)
- **Database Connections**
- **Resource Usage** (CPU, Memory)

### SLIs/SLOs Configurados
- **Availability SLO**: 99.5%
- **Latency SLO**: P95 < 1s
- **Error Budget**: Calculado automáticamente

---

## 🚨 Alertas Configuradas

| Alert | Severity | Threshold | Description |
|-------|----------|-----------|-------------|
| **ErrorBudgetBurnRateCritical** | CRITICAL | 10x | Error budget agotándose rápidamente |
| **HighLatency** | WARNING | P95 > 1s | Tiempo de respuesta alto |
| **QueueBackup** | WARNING | > 100 votos | Cola de procesamiento acumulándose |
| **HighActivity** | INFO | > 50 votes/min | Actividad inusualmente alta |

---

## 🔍 Distributed Tracing

La aplicación está configurada para enviar traces a Jaeger:

```bash
# Port-forward Jaeger UI
kubectl port-forward -n tracing svc/jaeger-query 16686:16686

# Abrir en navegador
open http://localhost:16686

# Buscar traces del servicio "vote-service"
```

**Traces disponibles**:
- Vote → Redis (write vote)
- Worker → Redis → PostgreSQL (process vote)
- Result → PostgreSQL (read results)

---

## 📝 Logs Estructurados

```bash
# Ejemplo de query en Kibana
kubernetes.namespace:"voting-app" AND level:"ERROR"

# Ver logs de un servicio específico
kubernetes.namespace:"voting-app" AND kubernetes.container.name:"vote"

# Buscar votos específicos
kubernetes.namespace:"voting-app" AND message:"Vote processed"
```

---

## 🎬 Demo de 5 Minutos

Ver [DIA56-DEMO-SCRIPT.md](DIA56-DEMO-SCRIPT.md) para el guión completo de presentación.

**Resumen**:
1. **Arquitectura** (30s): Mostrar diagrama y componentes
2. **Métricas en Vivo** (2min): Grafana dashboards + load test
3. **Distributed Tracing** (1min): Jaeger request flow
4. **Alertas y SLOs** (30s): Prometheus alerts
5. **Logs** (1min): Kibana queries

---

## 🏆 Logros al Completar

✅ **Observabilidad Completa** - Métricas + Logs + Traces  
✅ **Business & Technical KPIs** - Dashboards para diferentes audiencias  
✅ **SLO-based Alerting** - Error budget methodology  
✅ **Production-Ready** - Patrones enterprise  
✅ **Portfolio Project** - Demo lista para entrevistas  

---

## 📚 Referencias

- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Grafana Dashboards](https://grafana.com/docs/grafana/latest/dashboards/)
- [Jaeger Tracing](https://www.jaegertracing.io/docs/)
- [The Four Golden Signals](https://sre.google/sre-book/monitoring-distributed-systems/)
- [SLO Best Practices](https://sre.google/workbook/implementing-slos/)

---

## 🆘 Troubleshooting

Ver [DIA56-GUIDE.md](DIA56-GUIDE.md) sección "Troubleshooting" para soluciones comunes.

---

**Challenge**: #DevOpsConRoxs Día 56  
**Fecha**: 30 de marzo de 2026  
**Autor**: Nicolas Herrera
