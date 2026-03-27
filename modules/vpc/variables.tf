# ==============================================================================
# MODULE: VPC — Input Variables
# ==============================================================================
# Variables are the public interface of a module.
# They allow the same module to be reused across environments (dev, prod, etc.)
# by simply passing different values from the calling configuration.
#
# Rules followed here:
#   - Every variable has a `type` — Terraform validates input automatically.
#   - Every variable has a `description` — this IS the documentation.
#   - Sensitive variables are marked `sensitive = true`.
#   - Variables with safe defaults declare them; required ones do not.
#   - Critical variables use `validation` blocks to catch mistakes early.
# ==============================================================================

variable "project" {
  description = "Project identifier used in resource names and tags. Example: 'sca'."
  type        = string

  validation {
    # Enforce lowercase alphanumeric + hyphens only.
    # Resource names with spaces or special chars cause AWS API errors.
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "project must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment. Controls naming and tagging. Example: 'dev', 'prod'."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "vpc_cidr" {
  description = <<-EOT
    The IPv4 CIDR block for the VPC.
    This defines the total IP address space available to all subnets.
    A /16 gives 65,536 addresses and is the recommended size for most projects.
    Example: "10.0.0.0/16"
  EOT
  type        = string
  default     = "10.0.0.0/16"

  validation {
    # Validates the input is a proper CIDR notation.
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block. Example: 10.0.0.0/16."
  }
}

variable "availability_zones" {
  description = <<-EOT
    List of AWS Availability Zones to use for subnet distribution.
    One subnet (public and private) will be created per AZ.
    Must match the AWS region configured in the provider.
    Example: ["us-east-1a", "us-east-1b"]
  EOT
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones are required for fault tolerance."
  }
}

variable "public_subnet_cidrs" {
  description = <<-EOT
    List of CIDR blocks for public subnets — one per Availability Zone.
    Public subnets route internet traffic through the Internet Gateway.
    Resources here (e.g., Kong) can be reached from the public internet.
    Must be non-overlapping subnets within var.vpc_cidr.
    Example: ["10.0.1.0/24", "10.0.2.0/24"]
  EOT
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 public subnet CIDRs are required (one per AZ)."
  }
}

variable "private_subnet_cidrs" {
  description = <<-EOT
    List of CIDR blocks for private subnets — one per Availability Zone.
    Private subnets have no direct route to the internet.
    All internal services (databases, caches, Vault, etc.) live here.
    Must be non-overlapping subnets within var.vpc_cidr.
    Example: ["10.0.11.0/24", "10.0.12.0/24"]
  EOT
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least 2 private subnet CIDRs are required (one per AZ)."
  }
}
