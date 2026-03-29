variable "project" {
  description = "Project identifier used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment. Example: dev, staging, prod."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where Kong will be deployed."
  type        = string
}

variable "subnet_id" {
  description = "ID of the public subnet where the Kong EC2 instance will be launched."
  type        = string
}

variable "instance_profile_name" {
  description = "Name of the IAM instance profile to attach to the Kong EC2 instance."
  type        = string
}

variable "internal_sg_id" {
  description = "ID of the internal security group. Allows Kong to communicate with internal services."
  type        = string
}

variable "ssm_sg_id" {
  description = "ID of the SSM security group. Required for Session Manager access."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Kong. Use t3.small for MVP, scale up as traffic grows."
  type        = string
  default     = "t3.small"
}

