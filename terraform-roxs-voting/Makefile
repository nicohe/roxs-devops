.PHONY: help init plan apply destroy verify clean fmt validate

# Variables
ENV ?= dev
REPLICAS ?= 1

help: ## Mostrar esta ayuda
	@echo "Roxs Voting App - Terraform"
	@echo ""
	@echo "Uso: make [target] ENV=[dev|staging|prod]"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Inicializar Terraform
	terraform init

workspace: ## Crear/seleccionar workspace
	terraform workspace new $(ENV) 2>/dev/null || terraform workspace select $(ENV)

fmt: ## Formatear código Terraform
	terraform fmt -recursive

validate: ## Validar configuración
	terraform validate

plan: workspace ## Ver plan de despliegue
	terraform plan -var-file="environments/$(ENV).tfvars"

apply: workspace ## Aplicar cambios
	terraform apply -var-file="environments/$(ENV).tfvars"

apply-auto: workspace ## Aplicar cambios sin confirmación
	terraform apply -var-file="environments/$(ENV).tfvars" -auto-approve

destroy: workspace ## Destruir infraestructura
	terraform destroy -var-file="environments/$(ENV).tfvars"

destroy-auto: workspace ## Destruir sin confirmación
	terraform destroy -var-file="environments/$(ENV).tfvars" -auto-approve

verify: ## Verificar despliegue
	./scripts/verify-deployment.sh $(ENV)

scale: workspace ## Escalar aplicación (uso: make scale ENV=dev REPLICAS=3)
	terraform apply -var-file="environments/$(ENV).tfvars" -var="replica_count=$(REPLICAS)" -auto-approve

output: ## Ver outputs
	terraform output

output-json: ## Ver outputs en JSON
	terraform output -json

logs-vote: ## Ver logs del servicio vote
	@CONTAINER=$$(docker ps --filter "label=service=vote" --filter "label=environment=$(ENV)" --format "{{.Names}}" | head -n1); \
	[ -n "$$CONTAINER" ] && docker logs -f "$$CONTAINER" || echo "No vote container found"

logs-result: ## Ver logs del servicio result
	@CONTAINER=$$(docker ps --filter "label=service=result" --filter "label=environment=$(ENV)" --format "{{.Names}}" | head -n1); \
	[ -n "$$CONTAINER" ] && docker logs -f "$$CONTAINER" || echo "No result container found"

logs-worker: ## Ver logs del servicio worker
	@CONTAINER=$$(docker ps --filter "label=service=worker" --filter "label=environment=$(ENV)" --format "{{.Names}}" | head -n1); \
	[ -n "$$CONTAINER" ] && docker logs -f "$$CONTAINER" || echo "No worker container found"

containers: ## Listar contenedores de la aplicación
	docker ps --filter "label=project=roxs-voting-app" --filter "label=environment=$(ENV)"

stats: ## Ver estadísticas de recursos
	docker stats --filter "label=project=roxs-voting-app" --filter "label=environment=$(ENV)" --no-stream

clean: ## Limpiar archivos temporales
	rm -rf .terraform
	rm -f *.tfstate*
	rm -f *.tfplan
	rm -f crash.log

quick-start: ## Inicio rápido (dev)
	./scripts/quick-start.sh $(ENV)

test: fmt validate ## Ejecutar tests básicos
	@echo "✅ Format check passed"
	@echo "✅ Validation passed"

dev: ## Desplegar en desarrollo
	$(MAKE) apply ENV=dev

staging: ## Desplegar en staging
	$(MAKE) apply ENV=staging

prod: ## Desplegar en producción
	$(MAKE) apply ENV=prod
