# 📊 Resumen del Despliegue - Roxs Voting App en Kubernetes

## ✅ Desafío Completado: Día 35 - Semana 5

**Fecha:** 30 de Marzo de 2026  
**Autor:** Nicolas Herrera  
**Desafío:** #90DaysDevOps con Roxs

---

## 🎯 Objetivo Cumplido

Desplegar la aplicación completa **roxs-voting-app** en un clúster local de Kubernetes (Minikube), aplicando todos los conceptos aprendidos durante la Semana 5:

- ✅ Namespaces
- ✅ Deployments
- ✅ Services (ClusterIP y NodePort)
- ✅ ConfigMaps y Secrets
- ✅ PersistentVolumes y PersistentVolumeClaims
- ✅ Health Checks (Liveness y Readiness Probes)
- ✅ Resource Limits y Requests
- ✅ Labels y Selectors

---

## 🏗️ Arquitectura Desplegada

### Componentes de la Aplicación

| Componente | Imagen | Réplicas | Puerto | Tipo de Servicio | Estado |
|------------|--------|----------|--------|------------------|--------|
| **PostgreSQL** | postgres:15-alpine | 1 | 5432 | ClusterIP | ✅ Running |
| **Redis** | redis:alpine | 1 | 6379 | ClusterIP | ✅ Running |
| **Vote** | vote:local | 2 | 80 | NodePort (31080) | ✅ Running |
| **Worker** | worker:local | 1 | - | - | ✅ Running |
| **Result** | result:local | 2 | 3000 | NodePort (31081) | ✅ Running |

### Flujo de Datos

```
Usuario → Vote App (NodePort 31080)
           ↓
        Redis (Cache)
           ↓
        Worker (Procesa votos)
           ↓
      PostgreSQL (Base de datos)
           ↓
    Result App (NodePort 31081) ← Usuario
```

---

## 📁 Estructura de Archivos Creados

```
voting-app-k8s/
├── 01-namespace.yaml           # Namespace "voting-app"
├── 02-storage.yaml             # PVC con aprovisionador dinámico
├── 03-configs-secrets.yaml     # ConfigMaps y Secrets
├── 04-postgres.yaml            # PostgreSQL + Service
├── 05-redis.yaml               # Redis + Service
├── 06-vote.yaml                # Vote App + Service (NodePort)
├── 07-worker.yaml              # Worker (sin service)
├── 08-result.yaml              # Result App + Service (NodePort)
├── deploy.sh                   # Script automatizado de despliegue
├── README.md                   # Documentación completa
└── DEPLOYMENT_SUMMARY.md       # Este archivo
```

---

## 🚀 Proceso de Despliegue

### 1. Preparación del Entorno
```bash
# Iniciar Minikube
minikube start

# Verificar que kubectl funciona
kubectl version --client
```

### 2. Construcción de Imágenes Locales

**Problema encontrado:** Las imágenes `roxsross12/*` no están disponibles públicamente en Docker Hub.

**Solución:** Construir las imágenes localmente usando el Docker daemon de Minikube:

```bash
# Configurar Docker para usar el daemon de Minikube
eval $(minikube docker-env)

# Construir imágenes
docker build -t vote:local ./roxs-voting-app/vote
docker build -t worker:local ./roxs-voting-app/worker
docker build -t result:local ./roxs-voting-app/result
```

### 3. Ajustes de Configuración Realizados

#### a) Almacenamiento Persistente
**Problema:** El PV con `hostPath: /mnt/data/postgres` no existía en Minikube.  
**Solución:** Usar el aprovisionador dinámico `standard` de Minikube.

```yaml
spec:
  storageClassName: standard  # En lugar de "manual"
```

#### b) Variables de Entorno de las Aplicaciones

Después de revisar el código fuente, se descubrió que las aplicaciones esperan variables diferentes a las inicialmente configuradas:

**Vote App y Worker esperan:**
- `DATABASE_HOST` (no `POSTGRES_HOST`)
- `DATABASE_NAME` (no `POSTGRES_DB`)
- `DATABASE_USER` (no `POSTGRES_USER`)
- `DATABASE_PASSWORD` (no `POSTGRES_PASSWORD`)

**Solución:** Actualizar los manifiestos para mapear correctamente las variables.

#### c) Puertos de las Aplicaciones

**Problema:** Result App escucha en puerto 3000, no en puerto 80.  
**Solución:** Actualizar el manifiesto:

```yaml
ports:
- containerPort: 3000  # Cambiado de 80
```

Y los health checks:

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 3000  # Cambiado de 80
```

#### d) NodePorts

**Problema:** Los puertos 30080 y 30081 ya estaban asignados.  
**Solución:** Usar puertos 31080 y 31081.

---

## 📊 Estado Final del Despliegue

### Pods en Ejecución

```
NAME                       READY   STATUS    RESTARTS   AGE
postgres-96597d77b-fw9mh   1/1     Running   0          39m
redis-6b55cb4f76-zxvc9     1/1     Running   0          39m
result-575495d6cb-52f98    1/1     Running   0          17m
result-575495d6cb-lbknd    1/1     Running   0          17m
vote-64644bdc9d-g8wqc      1/1     Running   0          3m
vote-64644bdc9d-kw476      1/1     Running   0          3m
worker-7fb866bd8b-plbjx    1/1     Running   0          25m
```

### Services Configurados

```
NAME               TYPE        CLUSTER-IP       PORT(S)
postgres-service   ClusterIP   10.97.28.32      5432/TCP
redis-service      ClusterIP   10.109.166.13    6379/TCP
vote-service       NodePort    10.106.193.42    80:31080/TCP
result-service     NodePort    10.106.141.218   3000:31081/TCP
```

### Almacenamiento Persistente

```
NAME           STATUS   VOLUME                                     CAPACITY
postgres-pvc   Bound    pvc-fa7c7fe4-f0bb-4ed6-8568-5051f435eb9c   1Gi
```

---

## 🌐 Acceso a la Aplicación

### URLs de Acceso

- **Vote App (Frontend de votación):** http://192.168.49.2:31080
- **Result App (Visualización de resultados):** http://192.168.49.2:31081

### Comandos Útiles

```bash
# Abrir Vote App automáticamente
minikube service vote-service -n voting-app

# Abrir Result App automáticamente
minikube service result-service -n voting-app

# Ver la IP de Minikube
minikube ip

# Ver todos los recursos
kubectl get all -n voting-app
```

---

## 🧪 Pruebas Realizadas

### ✅ Test 1: Todos los Pods Corriendo
Todos los 7 pods están en estado `Running` con `READY 1/1`.

### ✅ Test 2: Services Disponibles
4 services configurados correctamente (2 ClusterIP internos, 2 NodePort externos).

### ✅ Test 3: Persistencia de Datos
PostgreSQL tiene almacenamiento persistente de 1Gi montado correctamente.

### ✅ Test 4: Procesamiento de Votos
Los logs del worker muestran que está procesando votos correctamente:

```
Processing vote for 'a' by 'ada00614ed33c08'
Vote updated for voter ada00614ed33c08: a
```

### ✅ Test 5: Conectividad Entre Servicios
- Vote App ←→ Redis: ✅
- Worker ←→ Redis: ✅
- Worker ←→ PostgreSQL: ✅
- Result App ←→ PostgreSQL: ✅

---

## 🏆 Desafíos Extras Completados

- ✅ **Health Checks:** Liveness y Readiness probes en todos los deployments
- ✅ **Resource Limits:** Definidos para todos los contenedores
- ✅ **Labels y Annotations:** Organizados por tier (frontend, backend, cache, database)
- ✅ **Script Automatizado:** `deploy.sh` para despliegue completo
- ✅ **Documentación Completa:** README.md con troubleshooting
- ✅ **Imágenes Propias:** Construidas localmente en lugar de usar imágenes públicas

---

## 📝 Lecciones Aprendidas

1. **Verificar el código fuente:** No asumir nombres de variables de entorno sin verificar el código.

2. **Aprovisionamiento dinámico:** En Minikube es mejor usar `storageClassName: standard` en lugar de crear PVs manualmente.

3. **ImagePullPolicy: Never:** Necesario cuando se usan imágenes locales construidas en el daemon de Minikube.

4. **Health checks precisos:** Verificar el puerto y path correctos que usa cada aplicación.

5. **NodePort únicos:** Los NodePorts son globales al clúster, no por namespace.

---

## 🛠️ Comandos de Gestión

### Ver Logs en Tiempo Real

```bash
# Vote App
kubectl logs -f deployment/vote -n voting-app

# Worker
kubectl logs -f deployment/worker -n voting-app

# Result App
kubectl logs -f deployment/result -n voting-app

# PostgreSQL
kubectl logs -f deployment/postgres -n voting-app
```

### Escalar Aplicaciones

```bash
# Escalar Vote App a 3 réplicas
kubectl scale deployment vote -n voting-app --replicas=3

# Escalar Result App a 3 réplicas
kubectl scale deployment result -n voting-app --replicas=3
```

### Debug

```bash
# Describir un pod
kubectl describe pod <pod-name> -n voting-app

# Ver eventos
kubectl get events -n voting-app --sort-by='.lastTimestamp'

# Ejecutar comandos en un pod
kubectl exec -it deployment/postgres -n voting-app -- psql -U postgres
```

### Limpieza

```bash
# Eliminar todo el namespace (y todos sus recursos)
kubectl delete namespace voting-app

# O eliminar componente por componente
kubectl delete -f voting-app-k8s/08-result.yaml
kubectl delete -f voting-app-k8s/07-worker.yaml
kubectl delete -f voting-app-k8s/06-vote.yaml
kubectl delete -f voting-app-k8s/05-redis.yaml
kubectl delete -f voting-app-k8s/04-postgres.yaml
kubectl delete -f voting-app-k8s/03-configs-secrets.yaml
kubectl delete -f voting-app-k8s/02-storage.yaml
kubectl delete -f voting-app-k8s/01-namespace.yaml
```

---

## 📚 Recursos Utilizados

- **Documentación oficial de Kubernetes:** https://kubernetes.io/docs/
- **Minikube Docs:** https://minikube.sigs.k8s.io/
- **90 Days of DevOps con Roxs:** https://90daysdevops.295devops.com/
- **Repositorio del Proyecto:** https://github.com/roxsross/roxs-devops-project90

---

## 🎉 Resultado Final

✅ **DESPLIEGUE EXITOSO**

La aplicación roxs-voting-app está completamente funcional en Kubernetes con:
- 7 pods corriendo
- 4 services configurados
- Almacenamiento persistente funcionando
- Alta disponibilidad (2 réplicas para vote y result)
- ConfigMaps y Secrets para gestión de configuración
- Health checks configurados
- Resource limits establecidos

**#DevOpsConRoxs** 🚀  
**#90DaysDevOps** 📚  
**#Kubernetes** ☸️  
**#Day35** ✨

---

**¡Desafío del Día 35 completado con éxito!** 🎊
