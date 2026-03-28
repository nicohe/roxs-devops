output "container_id" {
  description = "Container ID"
  value       = docker_container.redis.id
}

output "container_name" {
  description = "Container name"
  value       = docker_container.redis.name
}

output "internal_host" {
  description = "Internal hostname for service discovery"
  value       = "${var.app_name}-redis"
}
