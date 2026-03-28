# Volume for PostgreSQL data persistence
resource "docker_volume" "postgres_data" {
  name = "${var.app_name}-postgres-data-${var.environment}"

  labels {
    label = "project"
    value = "roxs-voting-app"
  }

  labels {
    label = "environment"
    value = var.environment
  }
}

# Pull PostgreSQL image
resource "docker_image" "postgres" {
  name         = "postgres:15-alpine"
  keep_locally = true
}

# PostgreSQL container
resource "docker_container" "postgres" {
  name  = "${var.app_name}-postgres-${var.environment}"
  image = docker_image.postgres.image_id

  restart = "unless-stopped"

  env = [
    "POSTGRES_USER=${var.database_user}",
    "POSTGRES_PASSWORD=${var.database_password}",
    "POSTGRES_DB=${var.database_name}"
  ]

  # Persistent volume
  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }

  # Network configuration
  networks_advanced {
    name    = var.network_name
    aliases = ["postgres", "database", "db", "${var.app_name}-postgres"]
  }

  # Healthcheck
  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U ${var.database_user}"]
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
      internal = 5432
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
    value = "database"
  }
}
