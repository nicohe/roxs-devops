# 🎬 Demo Script - 5 Minutos

## Preparación (antes de la demo)

```bash
# 1. Tener todo corriendo
cd observability-stack/scripts
./setup-observability.sh

# 2. Iniciar port-forwards
kubectl port-forward -n monitoring svc/prometheus-grafana 30091:80 &
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 30090:9090 &
kubectl port-forward -n voting-app svc/vote 30080:80 &
kubectl port-forward -n voting-app svc/result 30081:80 &

# 3. Verificar que todo funciona
./verify-stack.sh

# 4. Tener las siguientes tabs abiertas en el navegador:
# - http://localhost:30091 (Grafana - Business Dashboard)
# - http://localhost:30091 (Grafana - Technical Dashboard)
# - http://localhost:30090/targets (Prometheus Targets)
# - http://localhost:30090/alerts (Prometheus Alerts)
# - http://localhost:30080 (Voting App)
# - http://localhost:30081 (Results)
```

---

## 📝 Script de Demo (5 minutos)

### **Minuto 0:00 - 0:30: Introducción y Arquitectura**

> "Hola a todos. Hoy les voy a mostrar una implementación completa de observabilidad para una aplicación distribuida de votación."

**Mostrar**: Diagrama en README.md

> "La arquitectura incluye 3 microservicios (Vote, Worker, Result), bases de datos (Redis + PostgreSQL), y un stack completo de observabilidad con los 3 pilares: métricas (Prometheus), logs (ELK), y traces (Jaeger)."

**Puntos clave**:
- ✅ Aplicación multi-tier
- ✅ Stack de observabilidad enterprise
- ✅ SLO-based alerting
- ✅ Dashboards para Business + Technical

---

### **Minuto 0:30 - 1:00: Demostrar la App Funcionando**

**Cambiar a**: http://localhost:30080

> "Primero veamos la app en acción. Es simple: votamos entre gatos y perros."

**Acciones**:
1. Votar por "Cats" (click)
2. Votar por "Dogs" (click)
3. Cambiar a http://localhost:30081
4. Mostrar resultados en tiempo real

> "Los votos van a Redis, un worker los procesa y los guarda en PostgreSQL, y la página de resultados muestra el conteo en vivo usando WebSockets."

---

### **Minuto 1:00 - 2:30: Métricas en Vivo (Grafana)**

**Cambiar a**: Grafana Business Dashboard

> "Ahora lo interesante: vamos a generar tráfico y ver las métricas en tiempo real."

**Ejecutar en terminal**:
```bash
./load-test-demo.sh
```

> "Este script simula 10 usuarios votando concurrentemente durante 5 minutos."

**Mientras corre el load test, mostrar en Grafana**:

1. **Total Votes (Last Hour)** - gauge subiendo
   > "Aquí vemos el total de votos en la última hora aumentando en tiempo real."

2. **Votes Distribution (Cats vs Dogs)** - pie chart
   > "Distribución 60/40 porque el script genera más votos para gatos."

3. **Voting Rate** - time series
   > "Tasa de votación en votes/min. Vean cómo sube cuando iniciamos el load test."

4. **Response Time P95**
   > "Latencia P95. Nuestro SLO es < 1 segundo. Estamos en ~200ms. ✓"

**Cambiar a**: Grafana Technical Dashboard

5. **Request Rate (RPS per Service)**
   > "Request rate por servicio. Vote service manejando ~50 RPS, Result ~10 RPS."

6. **Error Rate %**
   > "Error rate en 0%. Nuestro SLO es < 0.5%, así que estamos dentro del presupuesto."

7. **CPU & Memory Usage**
   > "Recursos bajo control. Vote pods usando ~100m CPU, bien dentro de los límites."

---

### **Minuto 2:30 - 3:30: Distributed Tracing (Jaeger)**

**Cambiar a**: http://localhost:16686 (Jaeger UI)

> "Ahora veamos distributed tracing con Jaeger para entender el flujo completo de una request."

**Acciones**:
1. Service: `vote-service`
2. Click "Find Traces"
3. Seleccionar un trace reciente
4. Expandir spans

**Mostrar**:
```
POST /
  ├─ Redis SET vote
  ├─ Database operation
  └─ Response (200)
```

> "Aquí vemos el trace completo: el usuario vota, guardamos en Redis, y respondemos. Cada span muestra timing exacto. Total: ~150ms end-to-end."

**Bonus si hay tiempo**: Mostrar un trace de la cadena completa:
- Vote → Redis → Worker → PostgreSQL → Result

---

### **Minuto 3:30 - 4:00: SLO-Based Alerting**

**Cambiar a**: http://localhost:30090/alerts

> "Pasemos a alertas. No usamos alertas básicas, sino SLO-based alerting con error budget."

**Mostrar**: PrometheusRules

**Explicar alertas clave**:

1. **ErrorBudgetBurnRateCritical**
   > "Si consumimos el error budget a 10x la velocidad normal, alerta crítica. Significa que agotaríamos el presupuesto mensual en 3 días."

2. **HighLatencyP95**
   > "Si P95 excede 1s por 10 minutos, alerta. Nuestro SLO está en riesgo."

3. **QueueBackup**
   > "Si la cola de Redis supera 100 votos, significa que el worker no procesa lo suficientemente rápido."

**Cambiar a**: Prometheus Targets

> "Y aquí vemos que Prometheus está scraping exitosamente todos nuestros servicios cada 15 segundos."

**Mostrar**: Targets con estado "UP" (verde)

---

### **Minuto 4:00 - 4:30: SLO Dashboard & Error Budget**

**Volver a**: Grafana Technical Dashboard

**Scroll to**: SLO & Error Budget section

> "Ahora la parte más importante para un SRE: el error budget."

**Mostrar**:

1. **Availability (24h) - SLO: 99.5%**
   > "Disponibilidad actual: 100%. Por encima del SLO de 99.5%. ✓"

2. **Error Budget Remaining (24h)**
   > "Error budget: 100% restante. No hemos consumido nada porque no hay errores."

3. **Error Budget Burn Rate**
   > "Burn rate: 0x. Si esto sube a 10x, significa problemas serios."

> "Con este enfoque basado en SLOs, no tenemos que adivinar si las cosas van bien. Tenemos métricas objetivas vinculadas al SLA con clientes."

---

### **Minuto 4:30 - 5:00: Conclusión y Q&A**

> "Para resumir, implementamos:"

**Checklist visual**:
- ✅ **3 Pilares de Observabilidad**: Métricas + Logs + Traces
- ✅ **Dashboards Duales**: Business KPIs + Technical SRE metrics
- ✅ **SLO-Based Alerting**: Error budget methodology
- ✅ **Production-Ready**: Service discovery automático, escalable
- ✅ **Full GitOps**: Todo el stack como código en Git

> "Este patrón es exactamente lo que se usa en compañías como Google, Netflix, Uber."

**Bonus para portfolio**:
> "Todo está documentado en el repo con instrucciones paso a paso. Incluye:"
- Kubernetes manifests
- Grafana dashboards (JSON)
- PrometheusRules para alertas
- Load testing scripts
- Verificación automatizada

> "¿Preguntas?"

---

## 🎯 Puntos Clave para Recordar

| Aspecto | Valor Demo |
|---------|-----------|
| **Métricas en Vivo** | Dashboards actualizándose cada 10s |
| **SLO Principal** | 99.5% availability, P95 < 1s |
| **Error Budget** | Visualizado en tiempo real |
| **Traces** | End-to-end request flow |
| **Alertas** | SLO-based, no threshold-based |
| **Escalabilidad** | Service discovery automático |

---

## 🚨 Troubleshooting Durante Demo

### Si Grafana no muestra datos
```bash
# Verificar targets en Prometheus
curl http://localhost:30090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.namespace=="voting-app")'

# Re-aplicar ServiceMonitors
kubectl apply -f ../kubernetes/04-servicemonitors.yaml
```

### Si los pods no están ready
```bash
kubectl get pods -n voting-app
kubectl describe pod <pod-name> -n voting-app
kubectl logs <pod-name> -n voting-app
```

### Si el load test falla
```bash
# Verificar conectividad
curl http://localhost:30080/healthz
curl http://localhost:30081/healthz

# Ajustar configuración
export USERS=5
export DURATION=60
./load-test-demo.sh
```

---

## 📊 Métricas Esperadas Durante Demo

| Métrica | Valor Esperado |
|---------|----------------|
| Request Rate | 50-100 RPS |
| Error Rate | 0% |
| P95 Latency | 200-500ms |
| P99 Latency | < 1s |
| Queue Length | 0-5 votos |
| CPU per Pod | 50-150m |
| Memory per Pod | 80-200Mi |

---

**Tiempo Total**: 5 minutos  
**Nivel**: Intermediate to Advanced DevOps  
**Audiencia**: Hiring managers, Tech leads, SRE teams  
**Objetivo**: Demostrar expertise en observabilidad enterprise
