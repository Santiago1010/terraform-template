variable "project" {
  description = "Project identifier used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment. Example: dev, staging, prod."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the DocumentDB cluster will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DocumentDB subnet group. Requires at least two subnets in different AZs."
  type        = list(string)
}

variable "internal_sg_id" {
  description = "ID of the internal security group. Grants access from all EC2 instances within the VPC."
  type        = string
}

variable "instance_class" {
  description = "DocumentDB instance class. Use db.t3.medium as the minimum supported class."
  type        = string
  default     = "db.t3.medium"
}

variable "instance_count" {
  description = "Number of instances in the DocumentDB cluster. Minimum 1, recommended 3 for production."
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 16
    error_message = "instance_count must be between 1 and 16."
  }
}

variable "engine_version" {
  description = "DocumentDB engine version."
  type        = string
  default     = "5.0.0"
}

variable "master_username" {
  description = "Master username for the DocumentDB cluster."
  type        = string
  default     = "docdb"
}

variable "master_password" {
  description = "Master password for the DocumentDB cluster. Must be at least 8 characters."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.master_password) >= 8
    error_message = "master_password must be at least 8 characters."
  }
}

variable "backup_retention_days" {
  description = "Number of days to retain automated backups. Minimum 1."
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Prevent accidental deletion of the DocumentDB cluster."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot when deleting the cluster. Set to false in production."
  type        = bool
  default     = false
}
