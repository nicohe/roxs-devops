variable "app_name" {
  description = "Application name prefix"
  type        = string
  default     = "roxs-voting"
}

variable "database_user" {
  description = "PostgreSQL database user"
  type        = string
  default     = "postgres"
}

variable "database_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "votes"
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

variable "vote_image_tag" {
  description = "Docker image tag for vote service"
  type        = string
  default     = "latest"
}

variable "result_image_tag" {
  description = "Docker image tag for result service"
  type        = string
  default     = "latest"
}

variable "worker_image_tag" {
  description = "Docker image tag for worker service"
  type        = string
  default     = "latest"
}
