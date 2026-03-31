variable "project" {
  description = "Project identifier used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment. Example: dev, staging, prod."
  type        = string
}

variable "alarm_actions" {
  description = "List of ARNs to notify when an alarm fires. Typically an SNS topic ARN."
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "List of ARNs to notify when an alarm returns to OK state."
  type        = list(string)
  default     = []
}

variable "sqs_queue_names" {
  description = "Map of logical name to SQS queue name for DLQ depth alarms. Example: { jobs = 'sca-dev-jobs-dlq' }"
  type        = map(string)
  default     = {}
}

variable "ec2_instance_ids" {
  description = "Map of logical name to EC2 instance ID for CPU credit and status check alarms. Example: { kong = 'i-0abc123' }"
  type        = map(string)
  default     = {}
}

variable "cpu_credit_threshold" {
  description = "Minimum CPU credit balance before triggering an alarm on T3 instances."
  type        = number
  default     = 20
}

variable "evaluation_periods" {
  description = "Number of consecutive periods the metric must breach the threshold before alarming."
  type        = number
  default     = 2
}

variable "period_seconds" {
  description = "Granularity in seconds of each evaluation period."
  type        = number
  default     = 300
}
