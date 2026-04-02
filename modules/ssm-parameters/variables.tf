variable "project" {
  description = "Project identifier used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment. Example: dev, staging, prod."
  type        = string
}

variable "parameters" {
  description = "Map of parameters to create. Key is the logical name, value is the parameter configuration."
  type = map(object({
    description = string
    value       = string
    type        = optional(string, "String")
    tier        = optional(string, "Standard")
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.parameters :
      contains(["String", "StringList", "SecureString"], v.type)
    ])
    error_message = "type must be one of: String, StringList, SecureString."
  }

  validation {
    condition = alltrue([
      for k, v in var.parameters :
      contains(["Standard", "Advanced"], v.tier)
    ])
    error_message = "tier must be either Standard or Advanced."
  }
}
