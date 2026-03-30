variable "project" {
  description = "Project identifier used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment. Example: dev, staging, prod."
  type        = string
}

variable "name" {
  description = "Logical name for this n8n instance. Either 'infra' or 'app'."
  type        = string

  validation {
    condition     = contains(["infra", "app"], var.name)
    error_message = "name must be either 'infra' or 'app'."
  }
}

variable "vpc_id" {
  description = "ID of the VPC where n8n will be deployed."
  type        = string
}

variable "subnet_id" {
  description = "ID of the private subnet where the n8n EC2 instance will be launched."
  type        = string
}

variable "instance_profile_name" {
  description = "Name of the IAM instance profile to attach. Use n8n-infra-profile for infra, ec2-base-profile for app."
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
  description = "EC2 instance type for n8n. Use t3.small for MVP."
  type        = string
  default     = "t3.small"
}
