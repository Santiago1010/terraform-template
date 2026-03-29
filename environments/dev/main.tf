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

  project          = var.project
  environment      = var.environment
  aws_account_id   = data.aws_caller_identity.current.account_id
  infra_bucket_arn = module.s3.infra_bucket_arn
  state_bucket_arn = "arn:aws:s3:::tf-state-sca-2026-9xk2"
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
