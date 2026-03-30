# 🔄 CI/CD Pipeline - Voting App

## Descripción General

Pipeline completo de CI/CD con integración de seguridad (DevSecOps) para el proyecto Voting App.

---

## 📊 Workflows Disponibles

### 1. CI Pipeline (ci.yml) - Main Workflow

**Triggers:**
- Push a `develop` o `main`
- Pull requests a `develop` o `main`  
- Manual dispatch

**Jobs:**

```
┌─────────────────────────────────────────────────────┐
│  1️⃣ Tests Paralelos (vote, result, worker)         │
│     ├─ Lint                                         │
│     └─ Unit tests                                   │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│  2️⃣ Integration Tests                               │
│     ├─ Docker compose up                            │
│     ├─ Health checks                                │
│     └─ Smoke tests                                  │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│  3️⃣ Docker Build & Push (solo push)                │
│     ├─ Build images                                 │
│     └─ Push to ghcr.io                              │
│         • main → production, latest, <sha>          │
│         • develop → staging, <sha>                  │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│  4️⃣ Security Scan with Trivy 🔐 NEW!               │
│     ├─ Scan images for vulnerabilities             │
│     ├─ Generate SARIF reports                       │
│     ├─ Upload to GitHub Security                    │
│     ├─ Upload JSON artifacts                        │
│     └─ ❌ Fail if CRITICAL/HIGH found               │
└─────────────────────────────────────────────────────┘
```

---

## 🔐 Security Scan Job - Detalles

### Características

✅ **Escaneo automático** después de cada build  
✅ **Matrix strategy** para 3 servicios (vote, result, worker)  
✅ **Múltiples formatos** (SARIF, JSON, Table)  
✅ **Integración con GitHub Security**  
✅ **Fail on vulnerabilities** CRITICAL/HIGH  
✅ **Artifacts retention** 30 días  

### Severity Levels

| Nivel | Acción |
|-------|--------|
| **CRITICAL** | ❌ Falla pipeline |
| **HIGH** | ❌ Falla pipeline |
| **MEDIUM** | ⚠️ Warning (no falla) |
| **LOW** | ℹ️ Info (no falla) |

### Outputs

1. **GitHub Security Tab**
   - Permite visualizar vulnerabilidades en UI
   - Tracking histórico de issues
   - Integración con Dependabot

2. **Artifacts**
   - `trivy-scan-vote` (JSON + SARIF)
   - `trivy-scan-result` (JSON + SARIF)
   - `trivy-scan-worker` (JSON + SARIF)
   - Retention: 30 días

3. **Console Output**
   - Tabla de vulnerabilidades
   - Resumen por severity

### Permisos Requeridos

```yaml
permissions:
  contents: read        # Leer código
  packages: read        # Pull images from GHCR
  security-events: write # Subir a Security tab
```

---

## 🚀 Deploy Workflows

### deploy-staging.yml
- **Trigger**: Automático después de CI exitoso en `develop`
- **Runner**: Self-hosted staging
- **Environment**: staging
- **Deploy**: Docker Compose

### deploy-production.yml
- **Trigger**: Automático después de CI exitoso en `main`
- **Runner**: Self-hosted production
- **Environment**: production (con protección)
- **Deploy**: Docker Compose

### deploy-k8s-dev.yml
- **Trigger**: Push a `develop`
- **Deploy**: Kubernetes dev namespace

### deploy-k8s-staging.yml
- **Trigger**: Después de K8s dev exitoso
- **Deploy**: Kubernetes staging namespace

### deploy-k8s-prod.yml
- **Trigger**: Después de K8s staging en `main`
- **Confirmación**: Manual (input "deploy")
- **Deploy**: Kubernetes production namespace

---

## 🏥 Health Check Workflow

### health-check.yml
- **Schedule**: Cada 30 minutos
- **Manual**: Para staging o production
- **Script**: `scripts/health-check.sh`

---

## 📈 Uso y Monitoreo

### Ver Resultados de Security Scan

```bash
# En GitHub UI
Repository → Security → Code scanning alerts

# Ver artifacts en Actions
Actions → Último workflow run → Artifacts → trivy-scan-{service}

# Descargar localmente
gh run download <run-id> -n trivy-scan-vote
```

### Comandos Útiles

```bash
# Triggerar workflow manualmente
gh workflow run ci.yml

# Ver status de workflows
gh run list --workflow=ci.yml

# Ver logs de un job específico
gh run view <run-id> --log

# Descargar todos los artifacts
gh run download <run-id>
```

---

## 🔧 Configuración Local

Para probar el escaneo localmente antes de push:

```bash
# Build imágenes
./scripts/build-secure.sh

# Escanear con Trivy
./scripts/security-scan.sh

# Revisar reportes
cat reports/vote-scan.txt
cat reports/result-scan.txt
cat reports/worker-scan.txt
```

---

## 🎯 Best Practices Implementadas

### Seguridad
- ✅ Escaneo de vulnerabilidades automatizado
- ✅ Multi-stage builds
- ✅ Usuarios no root
- ✅ Health checks
- ✅ Secrets management

### CI/CD
- ✅ Tests paralelos
- ✅ Integration tests
- ✅ Matrix strategy para builds
- ✅ Fail fast cuando aplica
- ✅ Artifacts y reportes

### Deployments
- ✅ Entornos separados (dev, staging, prod)
- ✅ Self-hosted runners
- ✅ Environment protection rules
- ✅ Confirmación manual para producción
- ✅ Health checks post-deploy

---

## 📝 Mantenimiento

### Actualizar versión de Trivy

```yaml
uses: aquasecurity/trivy-action@0.28.0  # Cambiar versión aquí
```

### Agregar CVEs a ignorar

Editar `.trivyignore` en la raíz del repo:

```
# .trivyignore
CVE-2024-12345  # Justification: No fix available, low risk
```

### Modificar severities que fallan

En `ci.yml`, job `security-scan`, último step:

```yaml
severity: 'CRITICAL,HIGH'  # Modificar aquí
```

---

## 🔗 Referencias

- [GitHub Actions](https://docs.github.com/actions)
- [Trivy Action](https://github.com/aquasecurity/trivy-action)
- [GitHub Security](https://docs.github.com/code-security)
- [SARIF Format](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html)

---

**Última actualización**: Día 49 - Hardening del Voting-App  
**Challenge**: #SecureVotingAppConRoxs #90DiasDeDevOps
