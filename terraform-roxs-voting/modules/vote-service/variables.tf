variable "app_name" {
  description = "Application name prefix"
  type        = string
}

variable "network_name" {
  description = "Docker network name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "external_port" {
  description = "External port (null for internal only)"
  type        = number
  default     = null
}

variable "replica_count" {
  description = "Number of replicas"
  type        = number
  default     = 1
}

variable "memory_limit" {
  description = "Memory limit in MB"
  type        = number
  default     = 256
}

variable "redis_host" {
  description = "Redis hostname"
  type        = string
}

variable "database_host" {
  description = "Database hostname"
  type        = string
}

variable "database_user" {
  description = "Database user"
  type        = string
}

variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "Database name"
  type        = string
}

variable "option_a" {
  description = "Voting option A"
  type        = string
  default     = "Cats"
}

variable "option_b" {
  description = "Voting option B"
  type        = string
  default     = "Dogs"
}
