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

module "iam" {
  source = "../../modules/iam"

  project     = var.project
  environment = var.environment
}

module "security_groups" {
  source = "../../modules/security-groups"

  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  vpc_cidr    = module.vpc.vpc_cidr
}

module "ssm" {
  source = "../../modules/ssm"

  project                 = var.project
  environment             = var.environment
  session_timeout_minutes = 30
}
