variable "project" {
  description = "Project identifier used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment. Example: dev, staging, prod."
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID. Used to construct ARNs for IAM policy resources."
  type        = string
}

variable "infra_bucket_arn" {
  description = "ARN of the infra S3 bucket. Grants developers read access to logs."
  type        = string
}

variable "state_bucket_arn" {
  description = "ARN of the Terraform state S3 bucket. Grants infra-admin access to manage remote state."
  type        = string
}

variable "n8n_infra_bucket_arn" {
  description = "ARN of the infra S3 bucket. Grants n8n-infra access to read and write automation artifacts."
  type        = string
}
