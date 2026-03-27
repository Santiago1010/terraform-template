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
