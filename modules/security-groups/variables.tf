variable "project" {
  description = "Project identifier used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment. Example: dev, staging, prod."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where security groups will be created."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC. Used to allow internal traffic between all resources."
  type        = string
}
