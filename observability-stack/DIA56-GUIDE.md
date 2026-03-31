# 📖 Guía Detallada - Día 56

## Objetivo del Desafío

Implementar observabilidad end-to-end para el Voting App, demostrando los **3 pilares de observabilidad**:
1. **Métricas** (Prometheus + Grafana)
2. **Logs** (ELK Stack)
3. **Traces** (Jaeger)

---

## 📋 Tabla de Contenidos

1. [Pre-requisitos](#pre-requisitos)
2. [Arquitectura](#arquitectura)
3. [Instalación Paso a Paso](#instalación-paso-a-paso)
4. [Configuración de Métricas](#configuración-de-métricas)
5. [Dashboards de Grafana](#dashboards-de-grafana)
6. [Alertas y SLOs](#alertas-y-slos)
7. [Distributed Tracing](#distributed-tracing)
8. [Logs Centralizados](#logs-centralizados)
9. [Testing y Validación](#testing-y-validación)
10. [Troubleshooting](#troubleshooting)

---

## Pre-requisitos

### 1. Cluster Kubernetes

**Opción A: Kind (Recomendado para local)**
```bash
kind create cluster --name observability --config=kubernetes/kind-config.yaml
```

**Opción B: Minikube**
```bash
minikube start \
  --cpus 4 \
  --memory 8192 \
  --driver=docker \
  --kubernetes-version=v1.28.0
```

**Opción C: Docker Desktop**
- Activar Kubernetes en Settings
- Asignar al menos 4 CPUs y 8GB RAM

### 2. Herramientas CLI

```bash
# kubectl
brew install kubectl  # macOS
# o descargar desde https://kubernetes.io/docs/tasks/tools/

# helm (para instalar Prometheus stack)
brew install helm

# jq (para scripts)
brew install jq

# opcional: k9s para debugging
brew install k9s
```

### 3. Stack de Observabilidad (Día 55)

**Instalar Prometheus Stack con Helm**:
```bash
# Agregar repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Crear namespace
kubectl create namespace monitoring

# Instalar
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set grafana.adminPassword=admin123
```

**Verificar instalación**:
```bash
kubectl get pods -n monitoring
# Deberías ver: prometheus-operator, prometheus-0, grafana, alertmanager
```

---

## Arquitectura

### Diagrama de Flujo

```
┌─────────────────────────────────────────────────────────────┐
│                     USER TRAFFIC                            │
└────────────────────┬────────────────────────────────────────┘
                     │
         ┌───────────┴──────────┐
         │                      │
    ┌────▼─────┐          ┌────▼──────┐
    │   Vote   │          │  Result   │
    │ (Flask)  │          │ (Node.js) │
    └────┬─────┘          └────┬──────┘
         │                     │
         │    ┌──────────┐     │
         └────►  Redis   ◄─────┤
         │    └────┬─────┘     │
         │         │           │
         │    ┌────▼──────┐    │
         │    │  Worker   │    │
         │    │ (Node.js) │    │
         │    └────┬──────┘    │
         │         │           │
         │    ┌────▼──────┐    │
         └────► Postgres  ◄────┘
              └───────────┘

            INSTRUMENTATION LAYER
    ┌────────────────┬────────────────┬─────────────┐
    │   /metrics     │   /healthz     │  Traces     │
    │   endpoints    │   endpoints    │  (Jaeger)   │
    └────────┬───────┴────────┬───────┴─────┬───────┘
             │                │             │
    ┌────────▼────────────────▼─────────────▼───────┐
    │         PROMETHEUS SCRAPING                    │
    │   (ServiceMonitors - every 15s)                │
    └────────┬───────────────────────────────────────┘
             │
    ┌────────▼────────┐
    │   PROMETHEUS    │  ◄─── PrometheusRules (Alerts)
    │   (TSDB)        │
    └────────┬────────┘
             │
    ┌────────▼────────┐
    │    GRAFANA      │  ◄─── Dashboards (Business + Technical)
    │   (Dashboards)  │
    └─────────────────┘
```

### Componentes

| Componente | Propósito | Puerto | Namespace |
|------------|-----------|--------|-----------|
| **Vote** | Frontend votación | 80 | voting-app |
| **Result** | Frontend resultados | 3000 | voting-app |
| **Worker** | Procesador async | - | voting-app |
| **Redis** | Cola de mensajes | 6379 | voting-app |
| **PostgreSQL** | Base de datos | 5432 | voting-app |
| **Prometheus** | Métricas TSDB | 9090 | monitoring |
| **Grafana** | Dashboards | 3000 | monitoring |
| **Jaeger** | Distributed tracing | 16686 | tracing |

---

## Instalación Paso a Paso

### Paso 1: Clonar y Navegar

```bash
cd roxs-devops-project90/observability-stack
```

### Paso 2: Deploy Automatizado

**Opción A: Script Automatizado (Recomendado)**
```bash
cd scripts
chmod +x *.sh
./setup-observability.sh
```

**Opción B: Pasos Manuales**
```bash
# 1. Namespace
kubectl apply -f kubernetes/01-namespace.yaml

# 2. Bases de datos
kubectl apply -f kubernetes/02-databases.yaml

# Esperar a que estén ready
kubectl wait --for=condition=ready pod \
  -l app=redis -n voting-app --timeout=120s
kubectl wait --for=condition=ready pod \
  -l app=postgres -n voting-app --timeout=120s

# 3. Aplicación
kubectl apply -f kubernetes/03-voting-app.yaml

# Esperar a que estén ready
kubectl wait --for=condition=ready pod \
  -l app=vote -n voting-app --timeout=180s

# 4. ServiceMonitors
kubectl apply -f kubernetes/04-servicemonitors.yaml

# 5. Alertas
kubectl apply -f prometheus-rules/voting-app-alerts.yaml

# 6. Dashboards
kubectl create configmap voting-business-dashboard \
  --from-file=grafana-dashboards/business-dashboard.json \
  -n monitoring

kubectl create configmap voting-technical-dashboard \
  --from-file=grafana-dashboards/technical-dashboard.json \
  -n monitoring

kubectl label configmap voting-business-dashboard grafana_dashboard=1 -n monitoring
kubectl label configmap voting-technical-dashboard grafana_dashboard=1 -n monitoring
```

### Paso 3: Verificar Despliegue

```bash
./verify-stack.sh
```

Deberías ver:
```
✓ Passed:  15
! Warnings: 0
✗ Failed:  0
```

---

## Configuración de Métricas

### Instrumentación en el Código

Ya implementada en el código de la app. Revisar:

**Vote Service (Python/Flask)**:
```python
# roxs-voting-app/vote/app.py
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
metrics = PrometheusMetrics(app)

# Métricas automáticas:
# - http_requests_total
# - http_request_duration_seconds
# - http_request_size_bytes

# Métrica custom
votes_counter = Counter('votes_total', 'Total votes cast', ['option'])

@app.route('/', methods=['POST'])
def vote():
    option = request.form['vote']
    votes_counter.labels(option=option).inc()
    # ... resto del código
```

**Worker Service (Node.js)**:
```javascript
// roxs-voting-app/worker/main.js
const promClient = require('prom-client');

const votesProcessed = new promClient.Counter({
  name: 'votes_processed_total',
  help: 'Total votes processed by worker'
});

const queueLength = new promClient.Gauge({
  name: 'redis_queue_length',
  help: 'Number of votes in Redis queue'
});

// Endpoint de métricas
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', promClient.register.contentType);
  res.end(await promClient.register.metrics());
});
```

### ServiceMonitors

Los ServiceMonitors le indican a Prometheus qué endpoints scrapear:

```yaml
# kubernetes/04-servicemonitors.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: vote-metrics
  namespace: voting-app
  labels:
    release: prometheus  # IMPORTANTE: debe coincidir con el release de Helm
spec:
  selector:
    matchLabels:
      app: vote
  endpoints:
  - port: http
    path: /metrics
    interval: 15s      # Scrapear cada 15 segundos
    scrapeTimeout: 10s
```

**Verificar que Prometheus detecta los targets**:
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Abrir http://localhost:9090/targets
# Buscar "voting-app" - deberían estar en estado "UP" (verde)
```

---

## Dashboards de Grafana

### Importar Dashboards

Los dashboards ya están en ConfigMaps. Para verlos en Grafana:

```bash
# Port-forward a Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Abrir http://localhost:3000
# Usuario: admin
# Password: admin123 (o el que configuraste)
```

### Business Dashboard

**Panel 1: Total Votes (Last Hour)**
- Tipo: Gauge
- Query: `sum(increase(votes_total[1h]))`
- Muestra: Total de votos en la última hora

**Panel 2: Votes Distribution**
- Tipo: Pie Chart
- Queries:
  - Cats: `sum(votes_by_option{option="a"})`
  - Dogs: `sum(votes_by_option{option="b"})`

**Panel 3: Voting Rate**
- Tipo: Time Series
- Query: `rate(votes_total[5m]) * 60`
- Unidad: votes/min

**Panel 4: Service Availability**
- Tipo: Gauge
- Query: `100 - (sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100)`
- Thresholds:
  - Red: < 95%
  - Yellow: 95-99.5%
  - Green: > 99.5%

### Technical SRE Dashboard

Sigue las **Golden Signals** de SRE:

**1. Latency (Response Time)**
```promql
# P50
histogram_quantile(0.50, 
  sum(rate(http_request_duration_seconds_bucket{job="vote"}[1m])) by (le)
) * 1000

# P95 (SLO threshold)
histogram_quantile(0.95, 
  sum(rate(http_request_duration_seconds_bucket{job="vote"}[1m])) by (le)
) * 1000

# P99
histogram_quantile(0.99, 
  sum(rate(http_request_duration_seconds_bucket{job="vote"}[1m])) by (le)
) * 1000
```

**2. Traffic (Request Rate)**
```promql
sum(rate(http_requests_total{job="vote"}[1m])) by (job)
```

**3. Errors (Error Rate)**
```promql
(sum(rate(http_requests_total{job="vote",status=~"5.."}[1m])) 
 / sum(rate(http_requests_total{job="vote"}[1m]))) * 100
```

**4. Saturation (Resources)**
```promql
# CPU
sum(rate(container_cpu_usage_seconds_total{namespace="voting-app"}[1m])) by (pod)

# Memory
sum(container_memory_working_set_bytes{namespace="voting-app"}) by (pod)
```

---

## Alertas y SLOs

### Definición de SLOs

Para esta aplicación:

| SLI | SLO | Error Budget |
|-----|-----|--------------|
| **Availability** | 99.5% | 0.5% (3.6h/mes) |
| **Latency (P95)** | < 1s | - |
| **Error Rate** | < 0.5% | - |

### Error Budget Burn Rate

Fórmula:
```
burn_rate = (actual_error_rate / (1 - SLO))
```

**Ejemplos**:
- Error rate aumenta 1x (0.5%) → burn rate = 1x → normal
- Error rate aumenta 10x (5%) → burn rate = 10x → **CRITICAL**

**Interpretación**:
- Burn rate de 10x = consumirás el error budget mensual en **3 días**
- Burn rate de 3x = consumirás el error budget mensual en **10 días**

### Alertas Configuradas

Ver [prometheus-rules/voting-app-alerts.yaml](prometheus-rules/voting-app-alerts.yaml)

**Alertas Críticas**:

1. **ErrorBudgetBurnRateCritical**
   - Condición: Burn rate > 10x por 5 minutos
   - Acción: Page on-call engineer

2. **HighLatencyP99**
   - Condición: P99 > 3s por 5 minutos
   - Impacto: 1% de usuarios con experiencia degradada

3. **ServiceDown**
   - Condición: Pod no accesible por 2 minutos
   - Acción: Inmediata investigación

**Alertas de Warning**:

1. **ErrorBudgetBurnRateWarning**
   - Condición: Burn rate > 3x por 15 minutos
   - Acción: Monitorear tendencia

2. **HighLatencyP95**
   - Condición: P95 > 1s (SLO threshold) por 10 minutos
   - Acción: Investigar causa raíz

3. **QueueBackup**
   - Condición: Queue length > 100 por 5 minutos
   - Acción: Escalar worker o verificar DB

**Verificar alertas**:
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# http://localhost:9090/alerts
```

---

## Distributed Tracing

### Configuración de Jaeger

```bash
# Instalar Jaeger Operator
kubectl create namespace tracing
kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/crds/jaegertracing.io_jaegers_crd.yaml
kubectl create -n tracing -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/service_account.yaml
kubectl create -n tracing -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/role.yaml
kubectl create -n tracing -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/role_binding.yaml
kubectl create -n tracing -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/operator.yaml

# Crear instancia de Jaeger
cat <<EOF | kubectl apply -f -
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: jaeger
  namespace: tracing
spec:
  strategy: allInOne
  ingress:
    enabled: false
  allInOne:
    image: jaegertracing/all-in-one:latest
EOF

# Port-forward
kubectl port-forward -n tracing svc/jaeger-query 16686:16686

# Abrir http://localhost:16686
```

### Instrumentación de Traces

**Vote Service (Python)**:
```python
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.jaeger.thrift import JaegerExporter

# Setup tracing
trace.set_tracer_provider(TracerProvider())
jaeger_exporter = JaegerExporter(
    agent_host_name='jaeger-agent.tracing.svc.cluster.local',
    agent_port=6831,
)
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(jaeger_exporter)
)

# Auto-instrument Flask
FlaskInstrumentor().instrument_app(app)
```

### Analizando Traces en Jaeger

1. Seleccionar Service: `vote-service`
2. Click "Find Traces"
3. Ver lista de traces recientes
4. Click en un trace para ver detalles

**Información en cada trace**:
- **Duration**: Tiempo total del request
- **Spans**: Operaciones individuales
- **Tags**: Metadata (HTTP method, status code, etc.)
- **Logs**: Eventos durante la ejecución

---

## Logs Centralizados

### ELK Stack Setup (Opcional)

```bash
# Instalar ECK (Elastic Cloud on Kubernetes)
kubectl create -f https://download.elastic.co/downloads/eck/2.9.0/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/2.9.0/operator.yaml

# Crear namespace
kubectl create namespace logging

# Deploy Elasticsearch
cat <<EOF | kubectl apply -f -
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: elasticsearch
  namespace: logging
spec:
  version: 8.10.0
  nodeSets:
  - name: default
    count: 1
    config:
      node.store.allow_mmap: false
EOF

# Deploy Kibana
cat <<EOF | kubectl apply -f -
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: kibana
  namespace: logging
spec:
  version: 8.10.0
  count: 1
  elasticsearchRef:
    name: elasticsearch
EOF

# Deploy Filebeat
kubectl apply -f https://raw.githubusercontent.com/elastic/beats/8.10/deploy/kubernetes/filebeat-kubernetes.yaml
```

### Logs Structurados

**Formato JSON recomendado**:
```json
{
  "timestamp": "2026-03-30T10:15:30Z",
  "level": "INFO",
  "service": "vote",
  "msg": "Vote cast successfully",
  "vote": "a",
  "user_id": "abc123",
  "request_id": "xyz789",
  "duration_ms": 45
}
```

**Queries útiles en Kibana**:
```
# Errores en voting-app
kubernetes.namespace:"voting-app" AND level:"ERROR"

# Votos procesados
kubernetes.namespace:"voting-app" AND msg:"Vote processed"

# Request lentos (> 1s)
kubernetes.namespace:"voting-app" AND duration_ms:>1000

# Errores de PostgreSQL
kubernetes.namespace:"voting-app" AND "PostgreSQL" AND level:"ERROR"
```

---

## Testing y Validación

### 1. Verificación Manual

```bash
# Pods running
kubectl get pods -n voting-app

# Services accessible
kubectl get svc -n voting-app

# Métricas expuestas
kubectl exec -n voting-app deployment/vote -- curl -s http://localhost:80/metrics | head -20
```

### 2. Load Testing

```bash
cd scripts
./load-test-demo.sh

# Configurar parámetros
export DURATION=600    # 10 minutos
export USERS=20        # 20 usuarios concurrentes
export VOTE_RATE=10    # 10 votos/sec por usuario
./load-test-demo.sh
```

### 3. Chaos Testing (Avanzado)

```bash
# Matar un pod vote
kubectl delete pod -n voting-app -l app=vote --force --grace-period=0

# Observar en Grafana:
# - Availability baja temporalmente
# - Error rate aumenta
# - Alerta "HighErrorRate" se dispara
# - Auto-healing: Kubernetes recrea el pod
# - Métricas regresan a normal
```

### 4. Verificación Automatizada

```bash
./verify-stack.sh
```

---

## Troubleshooting

### Problema: Grafana no muestra datos

**Causa**: ServiceMonitors no están siendo detectados por Prometheus.

**Solución**:
```bash
# 1. Verificar label release
kubectl get servicemonitors -n voting-app -o yaml | grep "release:"

# Debe ser: release: prometheus

# 2. Verificar selector en PrometheusSpec
kubectl get prometheus -n monitoring prometheus-kube-prometheus-prometheus -o yaml | grep -A5 serviceMonitorSelector

# Si tiene: serviceMonitorSelectorNilUsesHelmValues: false
# Entonces busca label "release: prometheus"

# 3. Re-aplicar ServiceMonitors con label correcto
kubectl apply -f kubernetes/04-servicemonitors.yaml

# 4. Esperar ~30s y verificar targets
# http://localhost:9090/targets
```

### Problema: Pods en CrashLoopBackOff

**Diagnóstico**:
```bash
# Ver estado
kubectl get pods -n voting-app

# Describir pod
kubectl describe pod <pod-name> -n voting-app

# Ver logs
kubectl logs <pod-name> -n voting-app

# Ver logs del contenedor anterior (si crash reciente)
kubectl logs <pod-name> -n voting-app --previous
```

**Causas comunes**:
- Redis no accesible → Verificar que Redis pod está running
- PostgreSQL conexión rechazada → Verificar credenciales en env vars
- OOMKilled → Aumentar memory limits

### Problema: Alertas no funcionan

**Verificar**:
```bash
# 1. PrometheusRules aplicado
kubectl get prometheusrules -n voting-app

# 2. Verificar sintaxis
kubectl get prometheusrules -n voting-app voting-app-alerts -o yaml

# 3. Ver reglas cargadas en Prometheus
# http://localhost:9090/rules

# 4. Verificar expresión manualmente
# http://localhost:9090/graph
# Ejecutar: (sum(rate(http_requests_total{status=~"5.."}[1h])) / sum(rate(http_requests_total[1h]))) / (1 - 0.995) > 10
```

### Problema: Latencia alta

**Investigación**:
```bash
# 1. Verificar recursos
kubectl top pods -n voting-app

# 2. Verificar eventos
kubectl get events -n voting-app --sort-by='.lastTimestamp'

# 3. Escalar si es necesario
kubectl scale deployment vote --replicas=3 -n voting-app

# 4. Ver traces lentos en Jaeger
# http://localhost:16686
# Filter: duration > 1s
```

### Problema: Queue backup

**Causa**: Worker no procesa votos lo suficientemente rápido.

**Solución**:
```bash
# 1. Ver logs del worker
kubectl logs -n voting-app -l app=worker --tail=100

# 2. Verificar PostgreSQL conectividad
kubectl exec -n voting-app deployment/worker -- nc -zv postgres 5432

# 3. Escalar worker
kubectl scale deployment worker --replicas=2 -n voting-app

# 4. Monitorear queue length
watch -n 5 'kubectl exec -n voting-app deployment/worker -- curl -s http://localhost:3000/metrics | grep queue_length'
```

---

## Mejores Prácticas

### 1. Nomenclatura de Métricas

Seguir [Prometheus naming conventions](https://prometheus.io/docs/practices/naming/):
- `votes_total` (counter) - Total acumulado
- `redis_queue_length` (gauge) - Valor instantáneo
- `http_request_duration_seconds` (histogram) - Distribución

### 2. Granularidad de Scraping

- **Alta frecuencia** (5-15s): Servicios críticos user-facing
- **Media frecuencia** (30s): Servicios internos
- **Baja frecuencia** (1-5m): Métricas de infraestructura

### 3. Retention de Datos

```yaml
# En PrometheusSpec
spec:
  retention: 15d           # Retener datos 15 días
  retentionSize: "50GB"    # O hasta 50GB
```

### 4. High Availability

```yaml
# En Prometheus
spec:
  replicas: 2              # HA con 2 replicas
  
# En Grafana
spec:
  replicas: 2
  affinity:
    podAntiAffinity:       # Distribuir en diferentes nodos
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app: grafana
        topologyKey: kubernetes.io/hostname
```

### 5. Dashboards as Code

- Exportar dashboards como JSON
- Versionar en Git
- Importar via ConfigMaps con label `grafana_dashboard=1`
- Usar variables para multi-environment

---

## Recursos Adicionales

- [Prometheus Best Practices](https://prometheus.io/docs/practices/naming/)
- [Grafana Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)
- [Google SRE Book - Monitoring](https://sre.google/sre-book/monitoring-distributed-systems/)
- [Implementing SLOs](https://sre.google/workbook/implementing-slos/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)
- [ELK Stack Best Practices](https://www.elastic.co/guide/en/elasticsearch/reference/current/best-practices.html)

---

**Última actualización**: 30 de marzo de 2026  
**Versión**: 1.0  
**Autor**: Nicolas Herrera  
**Challenge**: #DevOpsConRoxs Día 56
