output "parameter_arns" {
  description = "Map of logical name to parameter ARN. Use in IAM policies that grant read access to specific parameters."
  value       = { for k, p in aws_ssm_parameter.parameters : k => p.arn }
}

output "parameter_names" {
  description = "Map of logical name to parameter name. Use when referencing parameters from application code or Ansible."
  value       = { for k, p in aws_ssm_parameter.parameters : k => p.name }
}
