variable "project" {
  description = "Project identifier used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment. Example: dev, staging, prod."
  type        = string
}

variable "logs_retention_days" {
  description = "Number of days before SSM session logs are automatically deleted."
  type        = number
  default     = 90
}

variable "backups_retention_days" {
  description = "Number of days before database backups are automatically deleted."
  type        = number
  default     = 30
}
