# Roxs Voting App - Despliegue en Kubernetes

Este directorio contiene todos los manifiestos de Kubernetes necesarios para desplegar la aplicación de votación roxs-voting-app en un clúster de Kubernetes (Minikube).

## 📋 Arquitectura de la Aplicación

La aplicación consta de 5 componentes:

| Componente | Imagen | Descripción | Tipo de Servicio |
|------------|--------|-------------|------------------|
| **vote** | roxsross12/vote | Frontend de votación | NodePort (30080) |
| **result** | roxsross12/result | Resultados en tiempo real | NodePort (30081) |
| **worker** | roxsross12/worker | Procesa votos | Sin servicio |
| **redis** | redis:alpine | Cache temporal | ClusterIP |
| **postgres** | postgres:15-alpine | Base de datos | ClusterIP |

## 🗂️ Estructura de Archivos

```
voting-app-k8s/
├── 01-namespace.yaml           # Namespace para organizar recursos
├── 02-storage.yaml             # PV y PVC para PostgreSQL
├── 03-configs-secrets.yaml     # ConfigMaps y Secrets
├── 04-postgres.yaml            # Deployment y Service de PostgreSQL
├── 05-redis.yaml               # Deployment y Service de Redis
├── 06-vote.yaml                # Deployment y Service de Vote App
├── 07-worker.yaml              # Deployment del Worker
├── 08-result.yaml              # Deployment y Service de Result App
├── deploy.sh                   # Script de despliegue automatizado
└── README.md                   # Este archivo
```

## 🚀 Despliegue Rápido

### Opción 1: Script Automatizado (Recomendado)

```bash
# Dar permisos de ejecución al script
chmod +x deploy.sh

# Ejecutar el script de despliegue
./deploy.sh
```

El script desplegará todos los componentes en el orden correcto y mostrará las URLs de acceso.

### Opción 2: Despliegue Manual

Si prefieres entender cada paso:

```bash
# 1. Crear namespace
kubectl apply -f 01-namespace.yaml

# 2. Configurar almacenamiento
kubectl apply -f 02-storage.yaml

# 3. Crear configuraciones
kubectl apply -f 03-configs-secrets.yaml

# 4. Desplegar PostgreSQL
kubectl apply -f 04-postgres.yaml
kubectl wait --for=condition=ready pod -l app=postgres -n voting-app --timeout=120s

# 5. Desplegar Redis
kubectl apply -f 05-redis.yaml
kubectl wait --for=condition=ready pod -l app=redis -n voting-app --timeout=60s

# 6. Desplegar aplicaciones
kubectl apply -f 06-vote.yaml
kubectl apply -f 07-worker.yaml
kubectl apply -f 08-result.yaml

# Esperar a que todo esté listo
kubectl wait --for=condition=ready pod -l app=vote -n voting-app --timeout=90s
kubectl wait --for=condition=ready pod -l app=result -n voting-app --timeout=90s
```

## 🔍 Verificación del Despliegue

### Ver todos los pods
```bash
kubectl get pods -n voting-app
```

Deberías ver algo similar a:
```
NAME                        READY   STATUS    RESTARTS   AGE
postgres-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
redis-xxxxxxxxxx-xxxxx      1/1     Running   0          1m
vote-xxxxxxxxxx-xxxxx       1/1     Running   0          1m
vote-xxxxxxxxxx-xxxxx       1/1     Running   0          1m
worker-xxxxxxxxxx-xxxxx     1/1     Running   0          1m
result-xxxxxxxxxx-xxxxx     1/1     Running   0          1m
result-xxxxxxxxxx-xxxxx     1/1     Running   0          1m
```

### Ver todos los servicios
```bash
kubectl get services -n voting-app
```

### Ver eventos (útil para debugging)
```bash
kubectl get events -n voting-app --sort-by='.lastTimestamp'
```

## 🌐 Acceso a la Aplicación

### Obtener las URLs de acceso

```bash
# Obtener la IP de Minikube
minikube ip

# O usar el comando de servicio de Minikube
minikube service vote-service -n voting-app --url
minikube service result-service -n voting-app --url
```

### Abrir en el navegador automáticamente
```bash
# Vote App
minikube service vote-service -n voting-app

# Result App
minikube service result-service -n voting-app
```

Por defecto:
- **Vote App**: http://[MINIKUBE_IP]:30080
- **Result App**: http://[MINIKUBE_IP]:30081

## 🧪 Testing de la Aplicación

### 1. Verificar que todos los pods estén corriendo
✅ Todos los pods deben estar en estado `Running`

### 2. Votar en la aplicación
- Acceder a http://[MINIKUBE_IP]:30080
- Votar entre Gato 🐱 y Perro 🐶

### 3. Ver resultados
- Acceder a http://[MINIKUBE_IP]:30081
- Los resultados deben actualizarse en tiempo real

### 4. Probar persistencia
```bash
# Eliminar el pod de PostgreSQL
kubectl delete pod -l app=postgres -n voting-app

# Esperar a que se recree automáticamente
kubectl get pods -n voting-app -w

# Verificar que los votos anteriores siguen ahí
```

## 📊 Monitoreo y Logs

### Ver logs de un componente
```bash
kubectl logs -f deployment/vote -n voting-app
kubectl logs -f deployment/worker -n voting-app
kubectl logs -f deployment/result -n voting-app
kubectl logs -f deployment/postgres -n voting-app
kubectl logs -f deployment/redis -n voting-app
```

### Describir un pod (útil para debugging)
```bash
kubectl describe pod [POD_NAME] -n voting-app
```

### Ver estado de los recursos
```bash
# Ver todo en el namespace
kubectl get all -n voting-app

# Ver persistent volumes
kubectl get pv,pvc -n voting-app

# Ver configmaps y secrets
kubectl get configmaps,secrets -n voting-app
```

## 🛠️ Troubleshooting

### Pod no inicia (Status: CrashLoopBackOff)
```bash
# Ver logs del pod
kubectl logs [POD_NAME] -n voting-app

# Ver eventos
kubectl describe pod [POD_NAME] -n voting-app
```

### Problemas de conectividad entre servicios
```bash
# Verificar que los services están creados
kubectl get services -n voting-app

# Verificar DNS interno
kubectl run -it --rm debug --image=busybox --restart=Never -n voting-app -- nslookup postgres-service
```

### Verificar configuraciones
```bash
# Ver ConfigMap
kubectl get configmap voting-app-config -n voting-app -o yaml

# Ver Secret (codificado en base64)
kubectl get secret postgres-secret -n voting-app -o yaml
```

### Worker no procesa votos
```bash
# Ver logs del worker
kubectl logs -f deployment/worker -n voting-app

# Verificar conexión a Redis y PostgreSQL
kubectl exec -it deployment/worker -n voting-app -- env | grep -E '(REDIS|POSTGRES)'
```

## 🔧 Configuración Personalizada

### Cambiar el número de réplicas

Para Vote App:
```bash
kubectl scale deployment vote -n voting-app --replicas=3
```

Para Result App:
```bash
kubectl scale deployment result -n voting-app --replicas=3
```

### Cambiar credenciales de PostgreSQL

1. Editar el Secret:
```bash
kubectl edit secret postgres-secret -n voting-app
```

2. Los valores deben estar en base64:
```bash
echo -n "nuevo_password" | base64
```

3. Reiniciar PostgreSQL:
```bash
kubectl rollout restart deployment/postgres -n voting-app
```

## 🧹 Limpieza

### Eliminar toda la aplicación
```bash
kubectl delete namespace voting-app
```

Esto eliminará todos los recursos en el namespace `voting-app`.

### Eliminar componentes individuales
```bash
kubectl delete -f 08-result.yaml
kubectl delete -f 07-worker.yaml
kubectl delete -f 06-vote.yaml
kubectl delete -f 05-redis.yaml
kubectl delete -f 04-postgres.yaml
kubectl delete -f 03-configs-secrets.yaml
kubectl delete -f 02-storage.yaml
kubectl delete -f 01-namespace.yaml
```

## 📚 Recursos Adicionales

### Comandos útiles de kubectl
```bash
# Ver todos los recursos en el namespace
kubectl get all -n voting-app

# Obtener YAML de un recurso existente
kubectl get deployment vote -n voting-app -o yaml

# Editar un recurso en vivo
kubectl edit deployment vote -n voting-app

# Ejecutar comandos dentro de un pod
kubectl exec -it deployment/postgres -n voting-app -- psql -U postgres

# Port forwarding (alternativa a NodePort)
kubectl port-forward service/vote-service 8080:80 -n voting-app
```

### Verificar health checks
```bash
# Ver detalles de los probes
kubectl describe deployment vote -n voting-app | grep -A 5 Liveness
kubectl describe deployment vote -n voting-app | grep -A 5 Readiness
```

## 🎯 Próximos Pasos

- [ ] Agregar Ingress Controller para acceso mediante dominios
- [ ] Implementar HorizontalPodAutoscaler para escalado automático
- [ ] Agregar NetworkPolicies para seguridad
- [ ] Implementar Prometheus + Grafana para monitoreo
- [ ] Configurar CI/CD con GitHub Actions
- [ ] Agregar Helm Charts para facilitar el despliegue

## 🏆 Desafío Extra Completado

- ✅ Health checks (liveness y readiness probes)
- ✅ Resource limits y requests
- ✅ Labels y annotations
- ✅ Script de deploy automatizado
- ✅ Documentación completa

---

**Día 35 - Desafío Final Semana 5** ✅  
**90 Días de DevOps con Roxs** 🚀  
#DevOpsConRoxs
