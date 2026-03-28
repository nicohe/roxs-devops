output "network_id" {
  description = "Network ID"
  value       = docker_network.voting_network.id
}

output "network_name" {
  description = "Network name"
  value       = docker_network.voting_network.name
}
