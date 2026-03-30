# 🚀 Día 42 - Cheat Sheet de Comandos

## 🎯 Quick Start

```bash
# Prueba local rápida
cd voting-app-k8s
./quick-start-k8s.sh local

# Deploy con Kustomize
kubectl apply -k overlays/dev
kubectl apply -k overlays/staging
kubectl apply -k overlays/prod
```

---

## 📦 Verificación de Deployments

```bash
# Ver todo en un namespace
kubectl get all -n voting-app-dev

# Ver solo pods
kubectl get pods -n voting-app-dev -o wide

# Ver con watch (actualización en tiempo real)
kubectl get pods -n voting-app-dev -w

# Ver deployments
kubectl get deployments -n voting-app-dev

# Ver servicios con NodePorts
kubectl get svc -n voting-app-dev
```

---

## 🔍 Debugging

```bash
# Ver logs de un componente
kubectl logs -l app=vote -n voting-app-dev --tail=50 -f
kubectl logs -l app=worker -n voting-app-dev --tail=50 -f
kubectl logs -l app=result -n voting-app-dev --tail=50 -f

# Ver logs de un pod específico
kubectl logs <pod-name> -n voting-app-dev -f

# Ver eventos recientes
kubectl get events -n voting-app-dev --sort-by='.lastTimestamp' | tail -20

# Describir un pod (ver errores)
kubectl describe pod <pod-name> -n voting-app-dev

# Entrar a un pod
kubectl exec -it <pod-name> -n voting-app-dev -- /bin/sh

# Ver configuración completa de un deployment
kubectl get deployment vote-dev -n voting-app-dev -o yaml
```

---

## 🔙 Rollback Manual

```bash
# Ver historial de rollouts
kubectl rollout history deployment/vote-dev -n voting-app-dev

# Rollback al deployment anterior
kubectl rollout undo deployment/vote-dev -n voting-app-dev

# Rollback a revisión específica
kubectl rollout undo deployment/vote-dev -n voting-app-dev --to-revision=2

# Verificar estado del rollout
kubectl rollout status deployment/vote-dev -n voting-app-dev
```

---

## ⚡ Scaling

```bash
# Escalar manualmente
kubectl scale deployment/vote-dev --replicas=3 -n voting-app-dev

# Ver réplicas actuales
kubectl get deployment vote-dev -n voting-app-dev

# Autoescalar (HPA - opcional)
kubectl autoscale deployment vote-dev --cpu-percent=80 --min=2 --max=5 -n voting-app-dev
```

---

## 🔄 Actualización de Imágenes

```bash
# Actualizar imagen de un deployment
kubectl set image deployment/vote-dev vote=ghcr.io/user/vote:new-tag -n voting-app-dev

# Verificar la actualización
kubectl rollout status deployment/vote-dev -n voting-app-dev

# Reiniciar deployment (usar imagen actual)
kubectl rollout restart deployment/vote-dev -n voting-app-dev
```

---

## 🌐 Acceso a Aplicaciones

```bash
# Con Minikube
minikube service vote-service-dev -n voting-app-dev
minikube service result-service-dev -n voting-app-dev

# Listar todos los servicios de Minikube
minikube service list

# Obtener IP de Minikube
minikube ip

# Port-forward (alternativa)
kubectl port-forward -n voting-app-dev svc/vote-service-dev 8080:80
kubectl port-forward -n voting-app-dev svc/result-service-dev 8081:3000
# Luego abre: http://localhost:8080 y http://localhost:8081

# Obtener NodePort
kubectl get svc vote-service-dev -n voting-app-dev -o jsonpath='{.spec.ports[0].nodePort}'
```

---

## 🧪 Testing y Validación

```bash
# Verificar que todos los pods están running
kubectl get pods -n voting-app-dev --field-selector=status.phase=Running

# Verificar pods NOT running (debe retornar vacío)
kubectl get pods -n voting-app-dev --field-selector=status.phase!=Running

# Contar pods por estado
kubectl get pods -n voting-app-dev -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}' | sort | uniq -c

# Ver readiness de pods
kubectl get pods -n voting-app-dev -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'

# Verificar health de PostgreSQL
kubectl exec -n voting-app-dev <postgres-pod> -- pg_isready -U postgres

# Test de conectividad interna
kubectl run -it --rm debug --image=busybox --restart=Never -n voting-app-dev -- sh
# Dentro del pod:
# nslookup redis-service-dev
# nslookup postgres-service-dev
# wget -O- http://vote-service-dev
```

---

## 📊 Monitoreo

```bash
# Ver uso de recursos (requiere metrics-server)
kubectl top nodes
kubectl top pods -n voting-app-dev

# Ver cuota de recursos
kubectl describe resourcequota -n voting-app-dev

# Ver límites de recursos de un pod
kubectl describe pod <pod-name> -n voting-app-dev | grep -A 5 "Limits"

# Ver configuración de health checks
kubectl get pod <pod-name> -n voting-app-dev -o yaml | grep -A 10 "livenessProbe"
kubectl get pod <pod-name> -n voting-app-dev -o yaml | grep -A 10 "readinessProbe"
```

---

## 🗑️ Limpieza

```bash
# Eliminar un namespace completo
kubectl delete namespace voting-app-dev
kubectl delete namespace voting-app-staging
kubectl delete namespace voting-app-prod

# Eliminar usando Kustomize
kubectl delete -k overlays/dev
kubectl delete -k overlays/staging
kubectl delete -k overlays/prod

# Eliminar pods específicos (se recrean automáticamente)
kubectl delete pod <pod-name> -n voting-app-dev

# Eliminar deployment (elimina pods asociados)
kubectl delete deployment vote-dev -n voting-app-dev

# Forzar eliminación de pod atascado
kubectl delete pod <pod-name> -n voting-app-dev --force --grace-period=0
```

---

## 🔧 Configuración

```bash
# Ver ConfigMaps
kubectl get configmap -n voting-app-dev
kubectl describe configmap voting-app-config-dev -n voting-app-dev

# Ver Secrets
kubectl get secrets -n voting-app-dev
kubectl describe secret postgres-secret-dev -n voting-app-dev

# Ver valores de Secret (base64)
kubectl get secret postgres-secret-dev -n voting-app-dev -o yaml

# Decodificar Secret
kubectl get secret postgres-secret-dev -n voting-app-dev -o jsonpath='{.data.POSTGRES_USER}' | base64 -d

# Editar ConfigMap
kubectl edit configmap voting-app-config-dev -n voting-app-dev

# Actualizar Secret
kubectl create secret generic postgres-secret-dev \
  --from-literal=POSTGRES_USER=newuser \
  --from-literal=POSTGRES_PASSWORD=newpass \
  -n voting-app-dev \
  --dry-run=client -o yaml | kubectl apply -f -
```

---

## 🔐 Contextos y Namespaces

```bash
# Ver contextos disponibles
kubectl config get-contexts

# Cambiar de contexto
kubectl config use-context minikube

# Ver namespace actual
kubectl config view --minify --output 'jsonpath={..namespace}'

# Cambiar namespace por defecto
kubectl config set-context --current --namespace=voting-app-dev

# Ver todos los namespaces
kubectl get namespaces

# Crear namespace
kubectl create namespace voting-app-test
```

---

## 🎨 Kustomize

```bash
# Ver manifiestos generados (sin aplicar)
kubectl kustomize overlays/dev
kubectl kustomize overlays/staging
kubectl kustomize overlays/prod

# Ver diferencias antes de aplicar
kubectl diff -k overlays/dev

# Aplicar con Kustomize
kubectl apply -k overlays/dev

# Ver qué Kustomization está aplicada
kubectl get -k overlays/dev

# Eliminar con Kustomize
kubectl delete -k overlays/dev
```

---

## 🚀 GitHub Actions

```bash
# Ver status de workflows (desde CLI con gh)
gh workflow list
gh workflow view "Deploy to Kubernetes - Dev"
gh run list --workflow="Deploy to Kubernetes - Dev"
gh run view <run-id>

# Trigger manual workflow
gh workflow run "Deploy to Kubernetes - Production" \
  -f confirm=deploy

# Ver logs de un workflow run
gh run view <run-id> --log

# Re-run un workflow fallido
gh run rerun <run-id>
```

---

## 🐳 Docker (para construcción local)

```bash
# Construir imágenes localmente para Minikube
eval $(minikube docker-env)

docker build -t vote:local ./roxs-voting-app/vote
docker build -t worker:local ./roxs-voting-app/worker
docker build -t result:local ./roxs-voting-app/result

# Verificar imágenes
docker images | grep -E "vote|worker|result"

# Volver al docker daemon local
eval $(minikube docker-env -u)
```

---

## 📝 Comandos Útiles Generales

```bash
# Ver versión de kubectl
kubectl version --client

# Ver información del cluster
kubectl cluster-info

# Ver componentes del cluster
kubectl get componentstatuses

# Ver recursos disponibles
kubectl api-resources

# Ver explicación de un recurso
kubectl explain deployment
kubectl explain pod.spec

# Validar YAML antes de aplicar
kubectl apply -f file.yaml --dry-run=client

# Generar YAML de un recurso existente
kubectl get deployment vote-dev -n voting-app-dev -o yaml > vote-backup.yaml

# Comparar archivos
kubectl diff -f file.yaml
```

---

## 🆘 Emergency Commands

```bash
# Ver pods con problemas
kubectl get pods -n voting-app-dev --field-selector=status.phase!=Running,status.phase!=Succeeded

# Restart todos los deployments de un namespace
for deploy in $(kubectl get deployments -n voting-app-dev -o name); do
  kubectl rollout restart $deploy -n voting-app-dev
done

# Eliminar pods con estado Unknown o terminating
kubectl get pods -n voting-app-dev | grep -E "Unknown|Terminating" | awk '{print $1}' | xargs kubectl delete pod -n voting-app-dev --force --grace-period=0

# Ver pods que se están reiniciando mucho
kubectl get pods -n voting-app-dev --sort-by='.status.containerStatuses[0].restartCount'

# Logs de todos los pods con label
kubectl logs -l app=vote -n voting-app-dev --all-containers=true --tail=20
```

---

## 📚 Recursos

```bash
# Documentación rápida
kubectl explain <recurso>
kubectl explain deployment.spec.strategy

# Cheat sheet oficial
# https://kubernetes.io/docs/reference/kubectl/cheatsheet/

# Auto-completion para bash
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc

# Auto-completion para zsh
source <(kubectl completion zsh)
echo "source <(kubectl completion zsh)" >> ~/.zshrc

# Alias útiles (agregar a ~/.bashrc o ~/.zshrc)
alias k=kubectl
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployments'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias kx='kubectl exec -it'
alias kaf='kubectl apply -f'
alias kdelf='kubectl delete -f'
```

---

**Para más información, ver:**
- [DIA42-CICD-KUBERNETES-GUIDE.md](./DIA42-CICD-KUBERNETES-GUIDE.md)
- [DIA42-ARQUITECTURA-CICD.md](./DIA42-ARQUITECTURA-CICD.md)
- [README.md](./README.md)
