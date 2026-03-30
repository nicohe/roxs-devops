# 🔐 Security Hardening Scripts - Guía de Uso

Este directorio contiene scripts para implementar el hardening de seguridad del Voting App (Día 49 - Desafío Final Semana 7).

## 📁 Scripts Disponibles

### 1. `build-secure.sh` - Build de Imágenes Seguras

Construye las imágenes Docker con todas las mejoras de seguridad aplicadas.

**Uso básico:**
```bash
chmod +x scripts/build-secure.sh
./scripts/build-secure.sh
```

**Con variables de entorno:**
```bash
# Personalizar registry y tag
DOCKER_REGISTRY=miusuario TAG=v1.0-secure ./scripts/build-secure.sh

# Build y push a Docker Hub
PUSH_IMAGES=true ./scripts/build-secure.sh
```

**Opciones:**
- `DOCKER_REGISTRY`: Prefijo del registry (default: `roxsross`)
- `TAG`: Tag de la imagen (default: `secure`)
- `PUSH_IMAGES`: Push a registry después del build (default: `false`)

---

### 2. `security-scan.sh` - Escaneo de Vulnerabilidades

Escanea las imágenes Docker usando Trivy y genera reportes de seguridad.

**Uso básico:**
```bash
chmod +x scripts/security-scan.sh
./scripts/security-scan.sh
```

**Características:**
- ✅ Instala Trivy automáticamente si no existe
- ✅ Escanea vulnerabilidades CRITICAL, HIGH y MEDIUM
- ✅ Genera reportes JSON y texto en `reports/`
- ✅ Falla si encuentra vulnerabilidades CRITICAL/HIGH
- ✅ Muestra tamaños de imágenes

**Output:**
```
reports/
├── vote-scan.json      # Reporte JSON del servicio vote
├── vote-scan.txt       # Reporte texto del servicio vote
├── result-scan.json    # Reporte JSON del servicio result
├── result-scan.txt     # Reporte texto del servicio result
├── worker-scan.json    # Reporte JSON del servicio worker
└── worker-scan.txt     # Reporte texto del servicio worker
```

---

## 🚀 Workflow Completo - Día 49

### Paso 1: Build de Imágenes Seguras

```bash
# Construir todas las imágenes con tag 'secure'
./scripts/build-secure.sh
```

Esto construirá:
- `roxsross/vote:secure`
- `roxsross/result:secure`
- `roxsross/worker:secure`

### Paso 2: Escaneo con Trivy

```bash
# Escanear todas las imágenes
./scripts/security-scan.sh
```

Verifica que no haya vulnerabilidades CRITICAL o HIGH.

### Paso 3: Testing Manual

```bash
# Opción 1: Usar docker-compose
docker-compose up -d

# Verificar servicios
curl http://localhost:5000  # Vote UI
curl http://localhost:5001  # Result UI

# Ver métricas de recursos
docker stats

# Verificar logs
docker-compose logs -f

# Detener servicios
docker-compose down
```

```bash
# Opción 2: Testing individual
# Vote service
docker run -d --name vote-test -p 5000:80 roxsross/vote:secure
docker stats vote-test --no-stream
docker logs vote-test
docker rm -f vote-test

# Result service
docker run -d --name result-test -p 5001:3000 roxsross/result:secure
docker stats result-test --no-stream
docker logs result-test
docker rm -f result-test

# Worker service
docker run -d --name worker-test -p 9000:3000 roxsross/worker:secure
docker stats worker-test --no-stream
docker logs worker-test
docker rm -f worker-test
```

### Paso 4: Verificar Métricas

```bash
# Tamaños de imágenes (objetivo: < 100MB)
docker images | grep secure

# Uso de recursos (objetivo: < 150MB RAM)
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" --no-stream

# Verificar que NO corren como root
docker exec vote-test whoami     # debe mostrar: appuser
docker exec result-test whoami   # debe mostrar: appuser
docker exec worker-test whoami   # debe mostrar: appuser
```

### Paso 5: Completar el Reporte

```bash
# Editar hardening-report.md con los resultados obtenidos
# - Tamaños de imágenes
# - Resultados de Trivy
# - Métricas de recursos
# - Screenshots de evidencias
```

### Paso 6: Push a Docker Hub (Opcional)

```bash
# Login en Docker Hub
docker login

# Push con el script
PUSH_IMAGES=true ./scripts/build-secure.sh

# O push manual
docker push roxsross/vote:secure
docker push roxsross/result:secure
docker push roxsross/worker:secure
```

---

## 🎯 Checklist de Validación

Antes de completar el desafío, verifica:

### Seguridad
- [ ] Todas las imágenes pasan el escaneo de Trivy (0 CRITICAL/HIGH)
- [ ] Todos los contenedores corren con usuario no root
- [ ] Health checks funcionando correctamente
- [ ] Solo puertos necesarios expuestos

### Performance
- [ ] Imágenes < 100MB
- [ ] Consumo RAM < 150MB por contenedor
- [ ] Aplicación responde correctamente
- [ ] No hay memory leaks evidentes

### Documentación
- [ ] hardening-report.md completado con todas las métricas
- [ ] Screenshots de antes/después incluidos
- [ ] Comandos documentados
- [ ] Lecciones aprendidas documentadas

---

## 🔧 Troubleshooting

### Error: "Trivy not found"
```bash
# macOS
brew install aquasecurity/trivy/trivy

# Linux
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy
```

### Error: "Permission denied on script"
```bash
chmod +x scripts/*.sh
```

### Error: "Docker daemon not running"
```bash
# macOS
open -a Docker

# Linux
sudo systemctl start docker
```

### Error en Health Check
```bash
# Verificar logs del contenedor
docker logs <container_name>

# Verificar que el endpoint /health existe
docker exec <container_name> curl http://localhost:80/health

# Para desarrollo, puedes comentar temporalmente el HEALTHCHECK
```

### Vulnerabilidades Persistentes
```bash
# Crear archivo .trivyignore en el directorio raíz
# Listar CVEs específicos que deben ser ignorados (con justificación)
echo "CVE-2024-XXXXX  # Justification: No fix available, low severity in our context" > .trivyignore
```

---

## 📊 Interpretación de Resultados

### Trivy Scan

```bash
# CRITICAL: Requiere acción inmediata
# HIGH: Debe ser corregido antes de producción
# MEDIUM: Planificar corrección
# LOW: Monitorear
```

### Docker Stats

```bash
# CPU %: < 5% en idle es normal
# MEM USAGE: < 150MB es el objetivo
# NET I/O: Depende del tráfico
# BLOCK I/O: Depende de las operaciones de disco
```

---

## 📚 Referencias Adicionales

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [OWASP Docker Security CheatSheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)

---

## 🎉 Completar el Desafío

Una vez que todo esté validado:

1. ✅ Commit de los cambios
```bash
git add .
git commit -m "feat: implementar hardening de seguridad - Día 49"
git push origin main
```

2. 📸 Compartir en redes sociales
- Screenshot de resultados de Trivy
- Comparación antes/después
- Hashtags: `#SecureVotingAppConRoxs #90DiasDeDevOps`

3. 🏆 Celebrar
- ¡Has desbloqueado la habilidad DevSecOps Builder! 🔐

---

**Autor**: Nicolas Herrera  
**Desafío**: Día 49 - Hardening del Voting-App  
**Fecha**: 30 de marzo de 2026
