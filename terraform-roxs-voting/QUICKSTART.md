# 🚀 Guía de Inicio Rápido - Roxs Voting App con Terraform

## ⚡ Despliegue en 3 pasos

### Paso 1: Inicializar Terraform

```bash
cd terraform-roxs-voting
terraform init
```

### Paso 2: Crear workspace de desarrollo

```bash
terraform workspace new dev
```

### Paso 3: Desplegar la aplicación

```bash
# Opción A: Usando Makefile (recomendado)
make dev

# Opción B: Usando terraform directamente
terraform apply -var-file="environments/dev.tfvars"

# Opción C: Usando el script quick-start
./scripts/quick-start.sh dev
```

## 🌐 Acceder a la aplicación

Una vez desplegada, accede a:

- **Votación:** http://localhost:8080
- **Resultados:** http://localhost:3000

## ✅ Verificar el despliegue

```bash
# Opción A: Script de verificación
./scripts/verify-deployment.sh dev

# Opción B: Makefile
make verify ENV=dev

# Opción C: Manual
docker ps --filter "label=project=roxs-voting-app"
```

## 📊 Comandos útiles con Makefile

```bash
# Ver todos los comandos disponibles
make help

# Ver el plan sin aplicar cambios
make plan ENV=dev

# Ver outputs del despliegue
make output

# Ver logs de un servicio
make logs-vote ENV=dev
make logs-result ENV=dev

# Escalar la aplicación
make scale ENV=dev REPLICAS=3

# Ver estadísticas de recursos
make stats ENV=dev

# Destruir la infraestructura
make destroy ENV=dev
```

## 🔄 Cambiar de entorno

```bash
# Staging
make staging

# Producción (¡cuidado!)
make prod
```

## 🧪 Testing de funcionalidad

```bash
# Votar por la opción A (Cats)
curl -X POST http://localhost:8080/ -d 'vote=a'

# Votar por la opción B (Dogs)
curl -X POST http://localhost:8080/ -d 'vote=b'

# Ver resultados
curl http://localhost:3000/
```

## 🗑️ Limpiar todo

```bash
# Opción A: Script de limpieza
./scripts/cleanup.sh dev

# Opción B: Makefile
make destroy-auto ENV=dev

# Opción C: Terraform directo
terraform workspace select dev
terraform destroy -var-file="environments/dev.tfvars" -auto-approve
```

## 📝 Estructura del proyecto

```
terraform-roxs-voting/
├── modules/              # Módulos reutilizables
│   ├── network/         # Red Docker
│   ├── database/        # PostgreSQL
│   ├── cache/           # Redis
│   ├── vote-service/    # App de votación
│   ├── result-service/  # App de resultados
│   └── worker-service/  # Procesador
├── environments/        # Configuraciones por entorno
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
├── scripts/            # Scripts de automatización
├── main.tf            # Configuración principal
├── Makefile           # Comandos simplificados
└── README.md          # Documentación completa
```

## 🚨 Troubleshooting rápido

### Error: Puerto en uso
```bash
# Ver qué usa el puerto 8080
lsof -i :8080
# Cambiar el puerto en environments/dev.tfvars o detener el proceso
```

### Error: Docker no está corriendo
```bash
# Verificar Docker
docker ps
# Si falla, iniciar Docker Desktop
```

### Error: Workspace no existe
```bash
# Crear el workspace
terraform workspace new dev
```

### Contenedores no inician
```bash
# Ver logs del contenedor
docker logs roxs-voting-vote-dev-1

# Ver estado de salud
docker ps --format "table {{.Names}}\t{{.Status}}"
```

## 🎯 Próximos pasos

1. ✅ Desplegar en dev y probar
2. 📝 Revisar el README.md completo
3. 🧪 Experimentar con staging
4. 🔧 Personalizar las configuraciones
5. 📊 Monitorear los recursos

## 💡 Tips

- Usa `make help` para ver todos los comandos disponibles
- Los workspaces mantienen estados separados para cada entorno
- Revisa los outputs con `terraform output` para ver información útil
- Los scripts en `scripts/` automatizan tareas comunes

## 📚 Más información

Ver el [README.md](README.md) completo para:
- Documentación detallada de cada módulo
- Configuración avanzada
- Best practices
- Troubleshooting completo
