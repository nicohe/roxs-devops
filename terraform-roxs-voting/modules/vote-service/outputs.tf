output "container_ids" {
  description = "Container IDs"
  value       = docker_container.vote[*].id
}

output "container_names" {
  description = "Container names"
  value       = docker_container.vote[*].name
}

output "service_url" {
  description = "Service URL"
  value       = var.external_port != null ? "http://localhost:${var.external_port}" : "internal"
}

output "replica_count" {
  description = "Number of replicas"
  value       = var.replica_count
}
