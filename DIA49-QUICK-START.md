# 🔥 Día 49 - Hardening del Voting-App - Quick Start

## 🎯 Objetivo del Desafío

Crear una versión **segura y optimizada** del Voting App aplicando todas las mejores prácticas de seguridad aprendidas en la Semana 7.

---

## ✅ Mejoras Implementadas

### 🔐 Seguridad
- ✅ **Multi-stage builds**: Reducción de superficie de ataque
- ✅ **Usuario no root**: Ejecución con `appuser` en todos los servicios
- ✅ **HEALTHCHECK**: Monitoreo automático de salud de servicios
- ✅ **Minimización de dependencias**: Eliminación de herramientas innecesarias
- ✅ **Imágenes base optimizadas**: `python:3.12-slim` y `node:20-alpine`
- ✅ **Trivy integrado en CI/CD**: Escaneo automático de vulnerabilidades

### 📊 Observabilidad
- ✅ Health endpoints en `/healthz`
- ✅ Métricas de Prometheus disponibles
- ✅ Logs estructurados y accesibles
- ✅ Reportes de seguridad en GitHub Security tab

### ⚡ Performance
- ✅ Optimización de capas Docker
- ✅ Cache de npm limpio
- ✅ Instalación determinística con `npm ci`

### 🔄 CI/CD
- ✅ Security scan automático en cada push
- ✅ Pipeline falla si hay vulnerabilidades CRITICAL/HIGH
- ✅ Reportes SARIF y JSON generados
- ✅ Artifacts con retention de 30 días

---

## 🚀 Guía Rápida de Uso

### 1️⃣ Build de Imágenes Seguras

```bash
# Construir todas las imágenes con mejoras de seguridad
./scripts/build-secure.sh
```

**Output esperado:**
- `roxsross/vote:secure` (< 100MB)
- `roxsross/result:secure` (< 100MB)
- `roxsross/worker:secure` (< 100MB)

---

### 2️⃣ Escaneo de Vulnerabilidades con Trivy

```bash
# Escanear todas las imágenes
./scripts/security-scan.sh
```

**Verifica:**
- ✅ 0 vulnerabilidades CRITICAL
- ✅ 0 vulnerabilidades HIGH
- ✅ Reportes generados en `reports/`

---

### 3️⃣ Testing de la Aplicación

```bash
# Opción A: Stack completo con docker-compose
docker-compose up -d

# Verificar servicios
curl http://localhost:5000  # Vote UI
curl http://localhost:5001  # Result UI

# Ver logs
docker-compose logs -f

# Ver métricas de recursos
docker stats

# Detener
docker-compose down
```

```bash
# Opción B: Testing individual de servicios
# Vote service
docker run -d --name vote-secure -p 5000:80 roxsross/vote:secure
docker stats vote-secure --no-stream
docker exec vote-secure whoami  # Debe mostrar: appuser
docker rm -f vote-secure

# Result service
docker run -d --name result-secure -p 5001:3000 roxsross/result:secure
docker stats result-secure --no-stream
docker exec result-secure whoami  # Debe mostrar: appuser
docker rm -f result-secure

# Worker service
docker run -d --name worker-secure roxsross/worker:secure
docker stats worker-secure --no-stream
docker exec worker-secure whoami  # Debe mostrar: appuser
docker rm -f worker-secure
```

---

### 4️⃣ Verificar Métricas de Performance

```bash
# Tamaño de imágenes (objetivo: < 100MB)
docker images | grep secure

# Uso de recursos en runtime
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

**Objetivos:**
- 📦 Imagen < 100MB
- 💾 RAM < 150MB por contenedor
- ⚡ CPU < 5% en idle

---

### 5️⃣ Completar el Reporte

Edita `hardening-report.md` con:
- ✅ Resultados de Trivy scan
- ✅ Tamaños de imágenes reales
- ✅ Métricas de recursos
- ✅ Screenshots de evidencias
- ✅ Lecciones aprendidas

---

### 6️⃣ Push a Docker Hub (Opcional)

```bash
# Login en Docker Hub
docker login

# Build y push en un solo comando
PUSH_IMAGES=true ./scripts/build-secure.sh

# O push manual
docker push roxsross/vote:secure
docker push roxsross/result:secure
docker push roxsross/worker:secure
```

---

## 📋 Cambios Realizados en los Dockerfiles

### Vote Service (Python/Flask)
```dockerfile
# ✅ Multi-stage build
# ✅ Usuario no root (appuser)
# ✅ HEALTHCHECK con /healthz
# ✅ Sin wget innecesario
# ✅ Optimización de capas
```

### Result Service (Node.js)
```dockerfile
# ✅ Multi-stage build
# ✅ Usuario no root (appuser)
# ✅ HEALTHCHECK con /healthz
# ✅ npm ci para builds determinísticos
# ✅ Cache limpiado
```

### Worker Service (Node.js)
```dockerfile
# ✅ Multi-stage build
# ✅ Usuario no root (appuser)
# ✅ HEALTHCHECK con /metrics
# ✅ npm ci para builds determinísticos
# ✅ Cache limpiado
```

---

## 🔍 Comandos de Troubleshooting

```bash
# Ver logs de un servicio específico
docker logs <container_name>

# Inspeccionar configuración de imagen
docker inspect roxsross/vote:secure

# Ver historial de capas
docker history roxsross/vote:secure

# Ejecutar comando dentro del contenedor
docker exec -it <container_name> sh

# Verificar health check
docker inspect <container_name> | grep -A 10 Health

# Ver procesos dentro del contenedor
docker top <container_name>
```

---

## 📊 Validación Final - Checklist

Antes de marcar el desafío como completado:

### Seguridad
- [ ] Todas las imágenes pasan Trivy scan (0 CRITICAL/HIGH)
- [ ] Todos los servicios corren con usuario no root
- [ ] Health checks funcionando correctamente
- [ ] Solo puertos necesarios expuestos

### Performance
- [ ] Todas las imágenes < 100MB
- [ ] Consumo RAM < 150MB por servicio
- [ ] Aplicación responde correctamente
- [ ] Sin degradación bajo carga ligera

### Documentación
- [ ] `hardening-report.md` completado
- [ ] Métricas reales documentadas
- [ ] Screenshots incluidos
- [ ] Lecciones aprendidas documentadas

---

## 📚 Documentación Adicional

- **Guía completa**: Ver `scripts/HARDENING-GUIDE.md`
- **Reporte de hardening**: Ver `hardening-report.md`
- **Scripts disponibles**:
  - `scripts/build-secure.sh` - Build de imágenes
  - `scripts/security-scan.sh` - Escaneo con Trivy

---

## 🎯 Comparación Antes/Después

### Antes del Hardening
```dockerfile
# Corriendo como root ❌
# Sin health checks ❌
# Dependencias innecesarias ❌
# Sin escaneo de vulnerabilidades ❌
```

### Después del Hardening
```dockerfile
# Usuario no root ✅
# Health checks activos ✅
# Dependencias mínimas ✅
# Escaneo automático ✅
# Multi-stage builds ✅
# Optimizado para producción ✅
```

---

## 🏆 Logro Desbloqueado

**DevSecOps Builder** 🔐

Has completado exitosamente el Día 49:
- ✅ Dockerfiles seguros
- ✅ Escaneo automatizado de vulnerabilidades
- ✅ Optimización de recursos
- ✅ Monitoreo y troubleshooting

---

## 📸 Compartir tu Logro

1. Screenshot de Trivy scan mostrando 0 CRITICAL/HIGH
2. Comparación de tamaños de imágenes
3. Métricas de recursos en docker stats

**Hashtags**: `#SecureVotingAppConRoxs #90DiasDeDevOps`

---

## 🆘 Soporte

Si encuentras problemas:
1. Revisa `scripts/HARDENING-GUIDE.md` - sección Troubleshooting
2. Verifica logs: `docker logs <container>`
3. Consulta `hardening-report.md` - sección Lecciones Aprendidas

---

**Challenge**: Día 49 - Hardening del Voting-App  
**Autor**: Nicolas Herrera  
**Fecha**: 30 de marzo de 2026  
**Status**: ✅ Ready to Execute
