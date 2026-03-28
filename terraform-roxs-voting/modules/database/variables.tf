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

variable "database_user" {
  description = "PostgreSQL database user"
  type        = string
}

variable "database_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "PostgreSQL database name"
  type        = string
}

variable "external_port" {
  description = "External port (null for internal only)"
  type        = number
  default     = null
}

variable "memory_limit" {
  description = "Memory limit in MB"
  type        = number
  default     = 512
}
