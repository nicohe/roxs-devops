# Build worker service image
resource "docker_image" "worker" {
  name = "${var.app_name}-worker:${var.image_tag}"

  build {
    context    = "${path.root}/../roxs-voting-app/worker"
    dockerfile = "Dockerfile"
    tag        = ["${var.app_name}-worker:${var.image_tag}"]
  }

  keep_locally = true
}

# Worker service containers (with replica support)
resource "docker_container" "worker" {
  count = var.replica_count

  name  = "${var.app_name}-worker-${var.environment}-${count.index + 1}"
  image = docker_image.worker.image_id

  restart = "unless-stopped"

  env = [
    "REDIS_HOST=${var.redis_host}",
    "DATABASE_HOST=${var.database_host}",
    "DATABASE_USER=${var.database_user}",
    "DATABASE_PASSWORD=${var.database_password}",
    "DATABASE_NAME=${var.database_name}"
  ]

  # Network configuration
  networks_advanced {
    name    = var.network_name
    aliases = ["worker", "${var.app_name}-worker"]
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
    value = "worker"
  }

  labels {
    label = "replica"
    value = tostring(count.index + 1)
  }
}
