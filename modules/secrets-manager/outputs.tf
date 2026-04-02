output "secret_arns" {
  description = "Map of logical name to secret ARN. Use in IAM policies that grant read access to specific secrets."
  value       = { for k, s in aws_secretsmanager_secret.secrets : k => s.arn }
}

output "secret_names" {
  description = "Map of logical name to secret name. Use when referencing secrets from application code."
  value       = { for k, s in aws_secretsmanager_secret.secrets : k => s.name }
}
