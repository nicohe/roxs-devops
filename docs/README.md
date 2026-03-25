# Dia 21 - CI/CD para Roxs Voting App

Este repositorio ya incluye los artefactos base para completar el desafio final de la semana 3:

- `docker-compose.yml`: entorno de desarrollo local con build desde codigo fuente.
- `docker-compose.staging.yml`: override para staging con imagenes publicadas en GHCR.
- `docker-compose.prod.yml`: override para produccion con imagenes publicadas en GHCR.
- `.github/workflows/ci.yml`: tests, smoke test integrado y build/push de imagenes.
- `.github/workflows/deploy-staging.yml`: despliegue automatico a staging usando self-hosted runner.
- `.github/workflows/deploy-production.yml`: despliegue a produccion con backup previo.
- `.github/workflows/health-check.yml`: validacion periodica cada 30 minutos.
- `scripts/deploy.sh`: levanta el stack segun el entorno.
- `scripts/health-check.sh`: valida estado de contenedores y endpoints HTTP.
- `scripts/backup.sh`: genera respaldo SQL desde PostgreSQL.

## Variables esperadas en GitHub

Secrets recomendados:

- `STAGING_DATABASE_USER`
- `STAGING_DATABASE_PASSWORD`
- `STAGING_DATABASE_NAME`
- `PRODUCTION_DATABASE_USER`
- `PRODUCTION_DATABASE_PASSWORD`
- `PRODUCTION_DATABASE_NAME`

Variables opcionales de entorno:

- `STAGING_OPTION_A`
- `STAGING_OPTION_B`
- `PRODUCTION_OPTION_A`
- `PRODUCTION_OPTION_B`

## Etiquetas de runners

Configura al menos dos self-hosted runners con estas etiquetas:

- `self-hosted`, `staging`
- `self-hosted`, `production`

## Flujo esperado

1. Push a `develop`.
2. Se ejecuta `CI`.
3. Se publican imagenes `:staging` en GHCR.
4. `Deploy Staging` actualiza el entorno y ejecuta health checks.
5. Push o merge a `main`.
6. Se ejecuta `CI`.
7. Se publican imagenes `:production` y `:latest`.
8. `Deploy Production` crea backup, despliega y valida la salud del stack.

## Pruebas locales utiles

```bash
cp .env.example .env
chmod +x scripts/*.sh

./scripts/deploy.sh development
./scripts/health-check.sh development

./scripts/deploy.sh staging
./scripts/health-check.sh staging

./scripts/backup.sh production
```

## Nota sobre aprobacion manual

La aprobacion manual para produccion se controla desde el environment `production` en GitHub. Activa los required reviewers en la configuracion del repositorio para que el workflow quede bloqueado antes de desplegar.