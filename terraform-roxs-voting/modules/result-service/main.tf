# Build result service image
resource "docker_image" "result" {
  name = "${var.app_name}-result:${var.image_tag}"

  build {
    context    = "${path.root}/../roxs-voting-app/result"
    dockerfile = "Dockerfile"
    tag        = ["${var.app_name}-result:${var.image_tag}"]
  }

  keep_locally = true
}

# Result service containers (with replica support)
resource "docker_container" "result" {
  count = var.replica_count

  name  = "${var.app_name}-result-${var.environment}-${count.index + 1}"
  image = docker_image.result.image_id

  restart = "unless-stopped"

  env = [
    "APP_PORT=3000",
    "DATABASE_HOST=${var.database_host}",
    "DATABASE_USER=${var.database_user}",
    "DATABASE_PASSWORD=${var.database_password}",
    "DATABASE_NAME=${var.database_name}"
  ]

  # Network configuration
  networks_advanced {
    name    = var.network_name
    aliases = ["result", "${var.app_name}-result"]
  }

  # Healthcheck
  healthcheck {
    test         = ["CMD", "wget", "-qO-", "http://localhost:3000/healthz"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 5
    start_period = "15s"
  }

  # Resource limits
  memory = var.memory_limit

  # Port mapping (only first replica gets external port)
  dynamic "ports" {
    for_each = var.external_port != null && count.index == 0 ? [1] : []
    content {
      internal = 3000
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
    value = "result"
  }

  labels {
    label = "replica"
    value = tostring(count.index + 1)
  }
}
