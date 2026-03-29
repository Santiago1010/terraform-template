variable "project" {
  description = "Project identifier used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment. Example: dev, staging, prod."
  type        = string
}

variable "session_timeout_minutes" {
  description = "Number of minutes before an idle SSM session is automatically terminated."
  type        = number
  default     = 30
}
