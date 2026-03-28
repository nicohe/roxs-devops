output "container_ids" {
  description = "Container IDs"
  value       = docker_container.worker[*].id
}

output "container_names" {
  description = "Container names"
  value       = docker_container.worker[*].name
}

output "replica_count" {
  description = "Number of replicas"
  value       = var.replica_count
}
