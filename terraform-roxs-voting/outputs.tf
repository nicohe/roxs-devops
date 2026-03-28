output "network_name" {
  description = "Docker network name"
  value       = module.network.network_name
}

output "vote_service_url" {
  description = "Vote service URL"
  value       = module.vote_service.service_url
}

output "result_service_url" {
  description = "Result service URL"
  value       = module.result_service.service_url
}

output "database_internal_host" {
  description = "Database internal hostname"
  value       = module.database.internal_host
}

output "cache_internal_host" {
  description = "Redis cache internal hostname"
  value       = module.cache.internal_host
}

output "environment" {
  description = "Current environment"
  value       = terraform.workspace
}

output "deployment_summary" {
  description = "Deployment summary"
  value = {
    environment     = terraform.workspace
    vote_url        = module.vote_service.service_url
    result_url      = module.result_service.service_url
    vote_replicas   = module.vote_service.replica_count
    worker_replicas = module.worker_service.replica_count
    result_replicas = module.result_service.replica_count
  }
}
