locals {
  app_name    = var.app_name
  environment = terraform.workspace

  # Configuración dinámica por workspace
  env_config = {
    dev = {
      vote_port     = 8080
      result_port   = 3000
      postgres_port = 5432
      redis_port    = 6379
      replica_count = 1
      memory_limit  = 256
    }
    staging = {
      vote_port     = 8081
      result_port   = 3001
      postgres_port = null
      redis_port    = null
      replica_count = 2
      memory_limit  = 512
    }
    prod = {
      vote_port     = 80
      result_port   = 3000
      postgres_port = null
      redis_port    = null
      replica_count = 3
      memory_limit  = 1024
    }
  }

  current_config = local.env_config[local.environment]
}

# Network Module
module "network" {
  source       = "./modules/network"
  network_name = "${local.app_name}-${local.environment}"
  environment  = local.environment
}

# Database Module
module "database" {
  source = "./modules/database"

  app_name          = local.app_name
  network_name      = module.network.network_name
  environment       = local.environment
  database_user     = var.database_user
  database_password = var.database_password
  database_name     = var.database_name
  external_port     = local.current_config.postgres_port
  memory_limit      = local.current_config.memory_limit

  depends_on = [module.network]
}

# Cache (Redis) Module
module "cache" {
  source = "./modules/cache"

  app_name      = local.app_name
  network_name  = module.network.network_name
  environment   = local.environment
  external_port = local.current_config.redis_port
  memory_limit  = local.current_config.memory_limit / 2

  depends_on = [module.network]
}

# Vote Service Module
module "vote_service" {
  source = "./modules/vote-service"

  app_name      = local.app_name
  network_name  = module.network.network_name
  environment   = local.environment
  image_tag     = var.vote_image_tag
  external_port = local.current_config.vote_port
  replica_count = local.current_config.replica_count
  memory_limit  = local.current_config.memory_limit

  redis_host        = module.cache.internal_host
  database_host     = module.database.internal_host
  database_user     = var.database_user
  database_password = var.database_password
  database_name     = var.database_name
  option_a          = var.option_a
  option_b          = var.option_b

  depends_on = [module.cache, module.database]
}

# Worker Service Module
module "worker_service" {
  source = "./modules/worker-service"

  app_name      = local.app_name
  network_name  = module.network.network_name
  environment   = local.environment
  image_tag     = var.worker_image_tag
  replica_count = local.current_config.replica_count
  memory_limit  = local.current_config.memory_limit

  redis_host        = module.cache.internal_host
  database_host     = module.database.internal_host
  database_user     = var.database_user
  database_password = var.database_password
  database_name     = var.database_name

  depends_on = [module.cache, module.database]
}

# Result Service Module
module "result_service" {
  source = "./modules/result-service"

  app_name      = local.app_name
  network_name  = module.network.network_name
  environment   = local.environment
  image_tag     = var.result_image_tag
  external_port = local.current_config.result_port
  replica_count = local.current_config.replica_count
  memory_limit  = local.current_config.memory_limit

  database_host     = module.database.internal_host
  database_user     = var.database_user
  database_password = var.database_password
  database_name     = var.database_name

  depends_on = [module.database]
}
