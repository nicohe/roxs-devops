# Pull Redis image
resource "docker_image" "redis" {
  name         = "redis:7-alpine"
  keep_locally = true
}

# Redis container
resource "docker_container" "redis" {
  name  = "${var.app_name}-redis-${var.environment}"
  image = docker_image.redis.image_id

  restart = "unless-stopped"

  # Network configuration
  networks_advanced {
    name    = var.network_name
    aliases = ["redis", "cache", "${var.app_name}-redis"]
  }

  # Healthcheck
  healthcheck {
    test     = ["CMD", "redis-cli", "ping"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }

  # Resource limits
  memory = var.memory_limit

  # Port mapping (only if external_port is set)
  dynamic "ports" {
    for_each = var.external_port != null ? [1] : []
    content {
      internal = 6379
      external = var.external_port
    }
  }

  labels {
    label = "project"
    value = "roxs-voting-app"
  }

  labels {
    label = "environment"
    value = var.environment
  }

  labels {
    label = "service"
    value = "cache"
  }
}
