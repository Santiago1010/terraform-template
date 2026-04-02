terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.38"
    }
  }

  backend "s3" {
    bucket         = "tf-state-sca-2026-9xk2"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    profile        = "terraform"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

module "vpc" {
  source = "../../modules/vpc"

  project              = var.project
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "security_groups" {
  source = "../../modules/security-groups"

  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  vpc_cidr    = module.vpc.vpc_cidr
}

module "s3" {
  source = "../../modules/s3"

  project        = var.project
  environment    = var.environment
  aws_account_id = data.aws_caller_identity.current.account_id
}

module "ssm" {
  source = "../../modules/ssm"

  project                 = var.project
  environment             = var.environment
  session_timeout_minutes = 30
  logs_bucket_arn         = module.s3.infra_bucket_arn
}

data "aws_caller_identity" "current" {}

module "iam" {
  source = "../../modules/iam"

  project              = var.project
  environment          = var.environment
  aws_account_id       = data.aws_caller_identity.current.account_id
  infra_bucket_arn     = module.s3.infra_bucket_arn
  state_bucket_arn     = "arn:aws:s3:::tf-state-sca-2026-9xk2"
  n8n_infra_bucket_arn = module.s3.infra_bucket_arn
}

module "kong" {
  source = "../../modules/kong"

  project               = var.project
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  subnet_id             = module.vpc.public_subnet_ids[0]
  instance_profile_name = module.iam.ec2_base_instance_profile_name
  internal_sg_id        = module.security_groups.internal_sg_id
  ssm_sg_id             = module.security_groups.ssm_sg_id
  instance_type         = "t3.small"
}

module "postgresql_infra" {
  source = "../../modules/postgresql"

  project               = var.project
  environment           = var.environment
  name                  = "infra"
  vpc_id                = module.vpc.vpc_id
  subnet_id             = module.vpc.private_subnet_ids[0]
  instance_profile_name = module.iam.ec2_base_instance_profile_name
  internal_sg_id        = module.security_groups.internal_sg_id
  ssm_sg_id             = module.security_groups.ssm_sg_id
  instance_type         = "t3.small"
  data_volume_size      = 50
}

module "postgresql_app" {
  source = "../../modules/postgresql"

  project               = var.project
  environment           = var.environment
  name                  = "app"
  vpc_id                = module.vpc.vpc_id
  subnet_id             = module.vpc.private_subnet_ids[1]
  instance_profile_name = module.iam.ec2_base_instance_profile_name
  internal_sg_id        = module.security_groups.internal_sg_id
  ssm_sg_id             = module.security_groups.ssm_sg_id
  instance_type         = "t3.small"
  data_volume_size      = 50
}

module "redis" {
  source = "../../modules/redis"

  project               = var.project
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  subnet_id             = module.vpc.private_subnet_ids[0]
  instance_profile_name = module.iam.ec2_base_instance_profile_name
  internal_sg_id        = module.security_groups.internal_sg_id
  ssm_sg_id             = module.security_groups.ssm_sg_id
  instance_type         = "t3.small"
}

module "vault" {
  source = "../../modules/vault"

  project               = var.project
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  subnet_id             = module.vpc.private_subnet_ids[0]
  instance_profile_name = module.iam.ec2_base_instance_profile_name
  internal_sg_id        = module.security_groups.internal_sg_id
  ssm_sg_id             = module.security_groups.ssm_sg_id
  instance_type         = "t3.small"
  data_volume_size      = 20
  postgresql_private_ip = module.postgresql_infra.private_ip
  vault_db_password     = var.vault_db_password
}

module "observability" {
  source = "../../modules/observability"

  project               = var.project
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  subnet_id             = module.vpc.private_subnet_ids[1]
  instance_profile_name = module.iam.ec2_base_instance_profile_name
  internal_sg_id        = module.security_groups.internal_sg_id
  ssm_sg_id             = module.security_groups.ssm_sg_id
  instance_type         = "t3.small"
  data_volume_size      = 50
}

module "rabbitmq" {
  source = "../../modules/rabbitmq"

  project               = var.project
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  subnet_id             = module.vpc.private_subnet_ids[0]
  instance_profile_name = module.iam.ec2_base_instance_profile_name
  internal_sg_id        = module.security_groups.internal_sg_id
  ssm_sg_id             = module.security_groups.ssm_sg_id
  instance_type         = "t3.small"
  data_volume_size      = 30
}

module "kafka" {
  source = "../../modules/kafka"

  project               = var.project
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  subnet_id             = module.vpc.private_subnet_ids[1]
  instance_profile_name = module.iam.ec2_base_instance_profile_name
  internal_sg_id        = module.security_groups.internal_sg_id
  ssm_sg_id             = module.security_groups.ssm_sg_id
  instance_type         = "t3.medium"
  data_volume_size      = 50
}

module "mongodb" {
  source = "../../modules/mongodb"

  project               = var.project
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  subnet_id             = module.vpc.private_subnet_ids[0]
  instance_profile_name = module.iam.ec2_base_instance_profile_name
  internal_sg_id        = module.security_groups.internal_sg_id
  ssm_sg_id             = module.security_groups.ssm_sg_id
  instance_type         = "t3.small"
  data_volume_size      = 50
}

module "consul" {
  source = "../../modules/consul"

  project               = var.project
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  subnet_id             = module.vpc.private_subnet_ids[1]
  instance_profile_name = module.iam.ec2_base_instance_profile_name
  internal_sg_id        = module.security_groups.internal_sg_id
  ssm_sg_id             = module.security_groups.ssm_sg_id
  instance_type         = "t3.small"
}

module "n8n_infra" {
  source = "../../modules/n8n"

  project               = var.project
  environment           = var.environment
  name                  = "infra"
  vpc_id                = module.vpc.vpc_id
  subnet_id             = module.vpc.private_subnet_ids[0]
  instance_profile_name = module.iam.n8n_infra_instance_profile_name
  internal_sg_id        = module.security_groups.internal_sg_id
  ssm_sg_id             = module.security_groups.ssm_sg_id
  instance_type         = "t3.small"
}

module "n8n_app" {
  source = "../../modules/n8n"

  project               = var.project
  environment           = var.environment
  name                  = "app"
  vpc_id                = module.vpc.vpc_id
  subnet_id             = module.vpc.private_subnet_ids[1]
  instance_profile_name = module.iam.ec2_base_instance_profile_name
  internal_sg_id        = module.security_groups.internal_sg_id
  ssm_sg_id             = module.security_groups.ssm_sg_id
  instance_type         = "t3.small"
}

module "sqs" {
  source = "../../modules/sqs"

  project     = var.project
  environment = var.environment
}

module "cloudwatch" {
  source = "../../modules/cloudwatch"

  project     = var.project
  environment = var.environment

  sqs_queue_names = {
    jobs   = "${var.project}-${var.environment}-jobs-dlq"
    events = "${var.project}-${var.environment}-events-dlq"
  }

  ec2_instance_ids = {
    kong             = module.kong.kong_instance_id
    postgresql_infra = module.postgresql_infra.instance_id
    postgresql_app   = module.postgresql_app.instance_id
    redis            = module.redis.instance_id
    vault            = module.vault.instance_id
    observability    = module.observability.instance_id
    rabbitmq         = module.rabbitmq.instance_id
    kafka            = module.kafka.instance_id
    mongodb          = module.mongodb.instance_id
    consul           = module.consul.instance_id
    n8n_infra        = module.n8n_infra.instance_id
    n8n_app          = module.n8n_app.instance_id
  }
}

module "kinesis" {
  source = "../../modules/kinesis"

  project     = var.project
  environment = var.environment

  streams = {
    events = {
      retention_hours = 24
      stream_mode     = "ON_DEMAND"
    }
    jobs = {
      retention_hours = 24
      stream_mode     = "ON_DEMAND"
    }
  }
}

module "secrets_manager" {
  source = "../../modules/secrets-manager"

  project     = var.project
  environment = var.environment

  secrets = {
    vault_db_password = {
      description     = "Password for the Vault database user in PostgreSQL."
      initial_value   = var.vault_db_password
      recovery_window = 7
    }
    kong_db_password = {
      description     = "Password for the Kong database user in PostgreSQL."
      initial_value   = null
      recovery_window = 7
    }
  }
}

module "ssm-parameters" {
  source = "../../modules/ssm-parameters"

  project     = var.project
  environment = var.environment

  parameters = {
    kong-private-ip = {
      description = "Private IP of the Kong instance."
      value       = module.kong.kong_private_ip
      type        = "String"
    }
    postgresql-infra-private-ip = {
      description = "Private IP of the infra PostgreSQL instance."
      value       = module.postgresql_infra.private_ip
      type        = "String"
    }
    postgresql-app-private-ip = {
      description = "Private IP of the app PostgreSQL instance."
      value       = module.postgresql_app.private_ip
      type        = "String"
    }
    redis-private-ip = {
      description = "Private IP of the Redis instance."
      value       = module.redis.private_ip
      type        = "String"
    }
    vault-private-ip = {
      description = "Private IP of the Vault instance."
      value       = module.vault.private_ip
      type        = "String"
    }
    observability-private-ip = {
      description = "Private IP of the observability instance."
      value       = module.observability.private_ip
      type        = "String"
    }
    rabbitmq-private-ip = {
      description = "Private IP of the RabbitMQ instance."
      value       = module.rabbitmq.private_ip
      type        = "String"
    }
    kafka-private-ip = {
      description = "Private IP of the Kafka instance."
      value       = module.kafka.private_ip
      type        = "String"
    }
    mongodb-private-ip = {
      description = "Private IP of the MongoDB instance."
      value       = module.mongodb.private_ip
      type        = "String"
    }
    consul-private-ip = {
      description = "Private IP of the Consul instance."
      value       = module.consul.private_ip
      type        = "String"
    }
    n8n-infra-private-ip = {
      description = "Private IP of the n8n-infra instance."
      value       = module.n8n_infra.private_ip
      type        = "String"
    }
    n8n-app-private-ip = {
      description = "Private IP of the n8n-app instance."
      value       = module.n8n_app.private_ip
      type        = "String"
    }
  }
}
