variable "project" {
  description = "Project identifier used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment. Example: dev, staging, prod."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the RDS instance will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the RDS subnet group. Requires at least two subnets in different AZs."
  type        = list(string)
}

variable "internal_sg_id" {
  description = "ID of the internal security group. Grants access from all EC2 instances within the VPC."
  type        = string
}

variable "instance_class" {
  description = "RDS instance class. Use db.t3.micro for Free Tier eligibility."
  type        = string
  default     = "db.t3.micro"
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16.3"
}

variable "allocated_storage" {
  description = "Initial allocated storage in GB. Free Tier includes up to 20GB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage in GB for autoscaling. Set to 0 to disable autoscaling."
  type        = number
  default     = 100
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability. Doubles the cost."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Prevent accidental deletion of the RDS instance."
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain automated backups. 0 disables backups."
  type        = number
  default     = 7
}

variable "master_username" {
  description = "Master username for the RDS instance."
  type        = string
  default     = "postgres"
}

variable "master_password" {
  description = "Master password for the RDS instance. Must be at least 8 characters."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.master_password) >= 8
    error_message = "master_password must be at least 8 characters."
  }
}
