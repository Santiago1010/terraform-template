variable "project" {
  description = "Project identifier used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment. Example: dev, staging, prod."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the ElastiCache cluster will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ElastiCache subnet group. Requires at least two subnets in different AZs."
  type        = list(string)
}

variable "internal_sg_id" {
  description = "ID of the internal security group. Grants access from all EC2 instances within the VPC."
  type        = string
}

variable "node_type" {
  description = "ElastiCache node type. Use cache.t3.micro for lowest cost."
  type        = string
  default     = "cache.t3.micro"
}

variable "engine_version" {
  description = "Redis engine version."
  type        = string
  default     = "7.1"
}

variable "num_cache_nodes" {
  description = "Number of cache nodes. Must be 1 for single-node clusters."
  type        = number
  default     = 1
}

variable "automatic_failover" {
  description = "Enable automatic failover. Requires num_cache_nodes greater than 1."
  type        = bool
  default     = false
}

variable "at_rest_encryption" {
  description = "Enable encryption at rest for the cluster."
  type        = bool
  default     = true
}

variable "transit_encryption" {
  description = "Enable in-transit encryption (TLS) for the cluster."
  type        = bool
  default     = true
}

variable "auth_token" {
  description = "Auth token for Redis AUTH. Required when transit_encryption is enabled."
  type        = string
  sensitive   = true
  default     = null
}

variable "snapshot_retention_days" {
  description = "Number of days to retain automatic snapshots. 0 disables snapshots."
  type        = number
  default     = 1
}
