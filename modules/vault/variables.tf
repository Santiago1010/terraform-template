variable "project" {
  description = "Project identifier used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment. Example: dev, staging, prod."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where Vault will be deployed."
  type        = string
}

variable "subnet_id" {
  description = "ID of the private subnet where the Vault EC2 instance will be launched."
  type        = string
}

variable "instance_profile_name" {
  description = "Name of the IAM instance profile to attach to the Vault EC2 instance."
  type        = string
}

variable "internal_sg_id" {
  description = "ID of the internal security group. Allows communication with other VPC resources."
  type        = string
}

variable "ssm_sg_id" {
  description = "ID of the SSM security group. Required for Session Manager access."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Vault. Use t3.small for MVP."
  type        = string
  default     = "t3.small"
}

variable "data_volume_size" {
  description = "Size in GB of the EBS data volume for Vault storage backend."
  type        = number
  default     = 20
}

variable "postgresql_private_ip" {
  description = "Private IP of the infra PostgreSQL instance. Used to configure Vault's database backend."
  type        = string
}

variable "vault_db_password" {
  description = "Password for the Vault database user in PostgreSQL. Must be set as a sensitive value."
  type        = string
  sensitive   = true
}
