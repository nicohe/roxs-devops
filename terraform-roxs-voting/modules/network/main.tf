resource "docker_network" "voting_network" {
  name   = var.network_name
  driver = "bridge"

  labels {
    label = "project"
    value = "roxs-voting-app"
  }

  labels {
    label = "environment"
    value = var.environment
  }

  labels {
    label = "managed-by"
    value = "terraform"
  }
}
