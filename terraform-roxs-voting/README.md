# Roxs Voting App - Terraform Implementation

Este proyecto implementa la aplicación Roxs Voting App utilizando Terraform con el provider Docker, como parte del desafío del Día 28 del programa 90 Days of DevOps.

## 📁 Estructura del Proyecto

```
terraform-roxs-voting/
├── modules/
│   ├── network/          # Red compartida Docker
│   ├── database/         # PostgreSQL con volúmenes persistentes
│   ├── cache/            # Redis para almacenamiento temporal
│   ├── vote-service/     # Aplicación de votación (Flask)
│   ├── result-service/   # Aplicación de resultados (Node.js)
│   └── worker-service/   # Procesador de votos (Node.js)
├── environments/
│   ├── dev.tfvars       # Variables de desarrollo
│   ├── staging.tfvars   # Variables de staging
│   └── prod.tfvars      # Variables de producción
├── scripts/
│   ├── quick-start.sh          # Despliegue rápido
│   ├── verify-deployment.sh    # Verificación del despliegue
│   ├── scale-app.sh            # Escalar aplicación
│   └── cleanup.sh              # Limpieza de recursos
├── main.tf              # Configuración principal
├── variables.tf         # Variables de entrada
├── outputs.tf          # Outputs del módulo
└── versions.tf         # Configuración de providers
```

## 🚀 Inicio Rápido

### Prerrequisitos

- Terraform >= 1.0
- Docker Desktop instalado y corriendo
- `jq` (opcional, para ver outputs formateados)

### Despliegue en entorno de desarrollo

```bash
cd terraform-roxs-voting

# Opción 1: Usando el script quick-start
./scripts/quick-start.sh dev

# Opción 2: Paso a paso manual
terraform workspace new dev
terraform init
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

### Acceso a la aplicación

- **Desarrollo:**
  - Vote: http://localhost:8080
  - Result: http://localhost:3000

- **Staging:**
  - Vote: http://localhost:8081
  - Result: http://localhost:3001

- **Producción:**
  - Vote: http://localhost:80
  - Result: http://localhost:3000

## 🏗️ Arquitectura de Módulos

### Network Module
Crea una red Docker de tipo bridge para la comunicación entre servicios.

### Database Module
- PostgreSQL 15 Alpine
- Volúmenes persistentes por entorno
- Healthchecks configurados
- Múltiples aliases de red (postgres, database, db)

### Cache Module
- Redis 7 Alpine
- Sin persistencia (cache temporal)
- Healthchecks configurados

### Vote Service Module
- Flask Python application
- Soporte para múltiples réplicas
- Build desde código fuente local
- Healthcheck en /healthz

### Result Service Module
- Node.js application
- Soporte para múltiples réplicas
- Build desde código fuente local
- Puerto configurable (3000)

### Worker Service Module
- Node.js background processor
- Procesa votos de Redis a PostgreSQL
- Soporte para múltiples réplicas

## 🔧 Configuración por Entornos

### Development (dev)
- Vote port: 8080
- Result port: 3000
- PostgreSQL: Expuesto en 5432
- Redis: Expuesto en 6379
- Réplicas: 1
- Memoria: 256MB por servicio

### Staging
- Vote port: 8081
- Result port: 3001
- PostgreSQL: Solo interno
- Redis: Solo interno
- Réplicas: 2
- Memoria: 512MB por servicio

### Production (prod)
- Vote port: 80
- Result port: 3000
- PostgreSQL: Solo interno
- Redis: Solo interno
- Réplicas: 3
- Memoria: 1024MB por servicio

## 📝 Comandos Útiles

### Gestión de workspaces

```bash
# Listar workspaces
terraform workspace list

# Crear nuevo workspace
terraform workspace new staging

# Cambiar de workspace
terraform workspace select prod

# Ver workspace actual
terraform workspace show
```

### Verificar despliegue

```bash
./scripts/verify-deployment.sh dev
```

### Escalar aplicación

```bash
# Escalar a 3 réplicas
./scripts/scale-app.sh dev 3
```

### Ver outputs

```bash
# Ver todos los outputs
terraform output

# Ver deployment summary
terraform output -json deployment_summary | jq '.'

# Ver URL del vote service
terraform output vote_service_url
```

### Limpieza

```bash
# Destruir infraestructura
./scripts/cleanup.sh dev

# O manualmente
terraform destroy -var-file="environments/dev.tfvars"
```

## 🧪 Testing y Validación

### Validación sintáctica

```bash
terraform fmt -check
terraform validate
terraform plan -var-file="environments/dev.tfvars"
```

### Testing de módulos individuales

```bash
# Test del módulo de red
cd modules/network
terraform init
terraform plan

# Test del módulo de database
cd modules/database
terraform init
terraform plan
```

### Verificación de contenedores

```bash
# Ver contenedores activos
docker ps --filter "label=project=roxs-voting-app"

# Ver por entorno
docker ps --filter "label=environment=dev"

# Logs de un servicio
docker logs roxs-voting-vote-dev-1

# Ejecutar comando en contenedor
docker exec -it roxs-voting-postgres-dev psql -U postgres
```

## 🚨 Troubleshooting

### Error: Puerto ya en uso

```bash
# Verificar qué proceso usa el puerto
lsof -i :8080

# Cambiar al workspace correcto
terraform workspace select dev
```

### Error: Imagen no se construye

```bash
# Verificar que el contexto existe
ls -la ../roxs-voting-app/vote

# Reconstruir manualmente
cd ../roxs-voting-app/vote
docker build -t test .
```

### Error: Servicios no se comunican

Verificar que todos los servicios estén en la misma red:

```bash
docker network inspect roxs-voting-dev
```

### Ver estado de salud de contenedores

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

## 📊 Monitoreo

### Ver estadísticas de recursos

```bash
docker stats --filter "label=project=roxs-voting-app" --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

### Ver logs en tiempo real

```bash
docker logs -f roxs-voting-vote-dev-1
```

## 🔄 Workflow de Desarrollo

1. **Desarrollo local:**
   ```bash
   terraform workspace select dev
   terraform apply -var-file="environments/dev.tfvars"
   ./scripts/verify-deployment.sh dev
   ```

2. **Testing en staging:**
   ```bash
   terraform workspace select staging
   terraform apply -var-file="environments/staging.tfvars"
   ./scripts/verify-deployment.sh staging
   ```

3. **Despliegue a producción:**
   ```bash
   terraform workspace select prod
   terraform plan -var-file="environments/prod.tfvars"
   # Revisar el plan
   terraform apply -var-file="environments/prod.tfvars"
   ```

## 🎯 Características Implementadas

✅ Infraestructura como código con Terraform
✅ Módulos reutilizables y composables
✅ Soporte para múltiples entornos (dev/staging/prod)
✅ Escalabilidad horizontal (réplicas configurables)
✅ Healthchecks para todos los servicios
✅ Volúmenes persistentes para base de datos
✅ Network isolation con Docker networks
✅ Límites de recursos configurables
✅ Scripts de automatización
✅ Testing y validación

## 📚 Recursos Adicionales

- [Terraform Docker Provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)
- [Docker Compose vs Terraform](https://www.hashicorp.com/resources/docker-compose-vs-terraform)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

## 🤝 Contribuciones

Este proyecto es parte del desafío 90 Days of DevOps. Para más información:

- [90 Days of DevOps](https://90daysdevops.295devops.com/)
- [Repositorio del curso](https://github.com/roxsross/roxs-devops-project90)

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la licencia del repositorio original.
