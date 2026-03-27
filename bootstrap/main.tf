terraform {
  # Specifies the minimum Terraform CLI version required to run this configuration.
  # This ensures compatibility with syntax and provider features used below.
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      # Defines the AWS provider source and version constraint.
      # Using a version range (~>) allows minor updates but avoids breaking changes.
      source  = "hashicorp/aws"
      version = "~> 6.38"
    }
  }
}

provider "aws" {
  # AWS region where all resources will be created.
  # This should match your infrastructure deployment region.
  region = var.aws_region

  # AWS CLI profile used for authentication.
  # Helps isolate credentials and environments (e.g., dev, staging, prod).
  profile = var.aws_profile
}

# ─────────────────────────────────────────
# S3: Remote Terraform State Storage
# ─────────────────────────────────────────

resource "aws_s3_bucket" "tf_state" {
  # Name of the S3 bucket that will store Terraform state files.
  # This must be globally unique across AWS.
  bucket = var.state_bucket_name

  lifecycle {
    # Prevents accidental deletion of the bucket.
    # Critical because losing this bucket means losing Terraform state.
    prevent_destroy = true
  }

  # Standardized tags for governance, cost tracking, and auditing.
  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "tf_state" {
  # Enables versioning on the state bucket.
  # This is essential for recovering from accidental changes or corruption.
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  # Enforces server-side encryption for all objects stored in the bucket.
  # Protects sensitive Terraform state data at rest.
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      # AES256 is AWS-managed encryption (SSE-S3).
      # Simpler and cost-effective compared to KMS for bootstrap setups.
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  # Ensures the bucket is never publicly accessible.
  # Terraform state can contain sensitive infrastructure data.
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ─────────────────────────────────────────
# DynamoDB: State Locking
# ─────────────────────────────────────────

resource "aws_dynamodb_table" "tf_locks" {
  # Table used by Terraform to implement state locking.
  # Prevents concurrent operations that could corrupt the state.
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST" # No capacity planning required
  hash_key     = "LockID"

  attribute {
    # Primary key used internally by Terraform to manage locks.
    name = "LockID"
    type = "S"
  }

  lifecycle {
    # Prevent accidental deletion of the lock table.
    # Without this, concurrent Terraform runs could break state consistency.
    prevent_destroy = true
  }

  tags = local.common_tags
}

# ────────────────────────────────────────
# Imports
# ────────────────────────────────────────
import {
  to = aws_s3_bucket.tf_state
  id = "tf-state-sca-2026-9xk2"
}

import {
  to = aws_dynamodb_table.tf_locks
  id = "terraform-locks"
}

# ─────────────────────────────────────────
# Locals
# ─────────────────────────────────────────

locals {
  # Common tagging strategy applied to all resources.
  # Helps with:
  # - Cost allocation
  # - Resource organization
  # - Governance and compliance
  common_tags = {
    Project     = var.project
    Environment = "bootstrap" # Indicates this is foundational infra
    ManagedBy   = "terraform"
  }
}

# ─────────────────────────────────────────
# Variables
# ─────────────────────────────────────────

variable "aws_region" {
  # AWS region for resource deployment.
  # Default is us-east-1, but should be overridden per environment.
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  # AWS CLI profile used for authentication.
  # Encourages separation of credentials across environments.
  type    = string
  default = "terraform"
}

variable "project" {
  # Logical project identifier used in tagging.
  # Helps group and identify resources across environments.
  type = string
}

variable "state_bucket_name" {
  # Name of the S3 bucket for storing Terraform state.
  # Must be globally unique.
  type = string
}

variable "dynamodb_table_name" {
  # Name of the DynamoDB table used for state locking.
  type = string
}

# ─────────────────────────────────────────
# Outputs
# ─────────────────────────────────────────

output "state_bucket_name" {
  # Exposes the S3 bucket name for use in backend configuration.
  value = aws_s3_bucket.tf_state.bucket
}

output "dynamodb_table_name" {
  # Exposes the DynamoDB table name for backend locking configuration.
  value = aws_dynamodb_table.tf_locks.name
}

output "state_bucket_arn" {
  # ARN of the S3 bucket.
  # Useful for IAM policies or cross-module references.
  value = aws_s3_bucket.tf_state.arn
}
