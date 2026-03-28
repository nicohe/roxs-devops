# Build vote service image
resource "docker_image" "vote" {
  name = "${var.app_name}-vote:${var.image_tag}"

  build {
    context    = "${path.root}/../roxs-voting-app/vote"
    dockerfile = "Dockerfile"
    tag        = ["${var.app_name}-vote:${var.image_tag}"]
  }

  keep_locally = true
}

# Vote service containers (with replica support)
resource "docker_container" "vote" {
  count = var.replica_count

  name  = "${var.app_name}-vote-${var.environment}-${count.index + 1}"
  image = docker_image.vote.image_id

  restart = "unless-stopped"

  env = [
    "REDIS_HOST=${var.redis_host}",
    "DATABASE_HOST=${var.database_host}",
    "DATABASE_USER=${var.database_user}",
    "DATABASE_PASSWORD=${var.database_password}",
    "DATABASE_NAME=${var.database_name}",
    "OPTION_A=${var.option_a}",
    "OPTION_B=${var.option_b}"
  ]

  # Network configuration
  networks_advanced {
    name    = var.network_name
    aliases = ["vote", "${var.app_name}-vote"]
  }

  # Healthcheck
  healthcheck {
    test         = ["CMD", "wget", "-qO-", "http://localhost/healthz"]
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
      internal = 80
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
    value = "vote"
  }

  labels {
    label = "replica"
    value = tostring(count.index + 1)
  }
}
