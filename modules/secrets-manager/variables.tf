variable "project" {
  description = "Project identifier used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment. Example: dev, staging, prod."
  type        = string
}

variable "secrets" {
  description = "Map of secrets to create. Key is the logical name, value is the secret configuration."
  type = map(object({
    description     = string
    initial_value   = optional(string, null)
    recovery_window = optional(number, 7)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.secrets :
      v.recovery_window >= 7 && v.recovery_window <= 30 || v.recovery_window == 0
    ])
    error_message = "recovery_window must be 0 (force delete) or between 7 and 30 days."
  }
}
