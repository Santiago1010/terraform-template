variable "project" {
  description = "Project identifier used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment. Example: dev, staging, prod."
  type        = string
}

variable "queues" {
  description = "Map of SQS queues to create. Key is the queue name suffix, value is the queue configuration."
  type = map(object({
    delay_seconds              = optional(number, 0)
    message_retention_seconds  = optional(number, 345600)
    visibility_timeout_seconds = optional(number, 30)
    receive_wait_time_seconds  = optional(number, 20)
  }))
  default = {
    jobs = {
      delay_seconds              = 0
      message_retention_seconds  = 345600
      visibility_timeout_seconds = 30
      receive_wait_time_seconds  = 20
    }
    events = {
      delay_seconds              = 0
      message_retention_seconds  = 345600
      visibility_timeout_seconds = 30
      receive_wait_time_seconds  = 20
    }
  }
}
