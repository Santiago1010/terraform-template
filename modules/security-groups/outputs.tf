output "internal_sg_id" {
  description = "ID of the internal security group. Attach to every EC2 instance to allow intra-VPC communication."
  value       = aws_security_group.internal.id
}

output "ssm_sg_id" {
  description = "ID of the SSM security group. Attach to every EC2 instance to enable Session Manager access."
  value       = aws_security_group.ssm.id
}
