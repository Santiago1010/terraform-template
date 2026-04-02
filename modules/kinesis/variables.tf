variable "project" {
  description = "Project identifier used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment. Example: dev, staging, prod."
  type        = string
}

variable "streams" {
  description = "Map of streams to create. Key is the logical name, value is the stream configuration."
  type = map(object({
    shard_count     = optional(number, null)
    retention_hours = optional(number, 24)
    stream_mode     = optional(string, "ON_DEMAND")
  }))
  default = {
    events = {
      retention_hours = 24
      stream_mode     = "ON_DEMAND"
    }
  }

  validation {
    condition = alltrue([
      for k, v in var.streams :
      contains(["ON_DEMAND", "PROVISIONED"], v.stream_mode)
    ])
    error_message = "stream_mode must be either ON_DEMAND or PROVISIONED."
  }

  validation {
    condition = alltrue([
      for k, v in var.streams :
      v.stream_mode == "ON_DEMAND" || (v.shard_count != null && v.shard_count > 0)
    ])
    error_message = "shard_count must be set and greater than 0 when stream_mode is PROVISIONED."
  }
}

variable "retention_hours" {
  description = "Default data retention period in hours. Minimum 24, maximum 8760 (365 days)."
  type        = number
  default     = 24

  validation {
    condition     = var.retention_hours >= 24 && var.retention_hours <= 8760
    error_message = "retention_hours must be between 24 and 8760."
  }
}
