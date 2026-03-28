output "container_id" {
  description = "Container ID"
  value       = docker_container.postgres.id
}

output "container_name" {
  description = "Container name"
  value       = docker_container.postgres.name
}

output "internal_host" {
  description = "Internal hostname for service discovery"
  value       = "${var.app_name}-postgres"
}

output "volume_name" {
  description = "Volume name"
  value       = docker_volume.postgres_data.name
}
