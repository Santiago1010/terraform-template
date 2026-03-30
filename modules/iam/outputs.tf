output "ec2_base_role_name" {
  description = "Name of the base IAM role for EC2 instances."
  value       = aws_iam_role.ec2_base.name
}

output "ec2_base_role_arn" {
  description = "ARN of the base IAM role. Useful for policy references and cross-module usage."
  value       = aws_iam_role.ec2_base.arn
}

output "ec2_base_instance_profile_name" {
  description = "Name of the instance profile. This is what you assign to an EC2 instance."
  value       = aws_iam_instance_profile.ec2_base.name
}

output "ec2_base_instance_profile_arn" {
  description = "ARN of the instance profile. Required when referencing the profile in launch templates."
  value       = aws_iam_instance_profile.ec2_base.arn
}

output "developer_role_arn" {
  description = "ARN of the developer IAM role. Assign to IAM users who need SSM and log access."
  value       = aws_iam_role.developer.arn
}

output "infra_admin_role_arn" {
  description = "ARN of the infra admin IAM role. Assign to IAM users who manage infrastructure."
  value       = aws_iam_role.infra_admin.arn
}

output "developer_policy_arn" {
  description = "ARN of the developer IAM policy. Useful for attaching to additional roles if needed."
  value       = aws_iam_policy.developer.arn
}

output "infra_admin_policy_arn" {
  description = "ARN of the infra admin IAM policy. Useful for attaching to additional roles if needed."
  value       = aws_iam_policy.infra_admin.arn
}

output "assume_developer_policy_arn" {
  description = "ARN of the policy to attach to IAM users who should assume the developer role."
  value       = aws_iam_policy.assume_developer.arn
}

output "assume_infra_admin_policy_arn" {
  description = "ARN of the policy to attach to IAM users who should assume the infra-admin role."
  value       = aws_iam_policy.assume_infra_admin.arn
}

output "n8n_infra_instance_profile_name" {
  description = "Instance profile name for the n8n-infra EC2 instance."
  value       = aws_iam_instance_profile.n8n_infra.name
}
