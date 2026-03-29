output "vpc_id" {
  description = "ID of the VPC created in this environment."
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC."
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.vpc.private_subnet_ids
}

output "ec2_base_instance_profile_name" {
  description = "Instance profile name to assign to EC2 instances."
  value       = module.iam.ec2_base_instance_profile_name
}

output "internal_sg_id" {
  description = "ID of the internal security group."
  value       = module.security_groups.internal_sg_id
}

output "ssm_sg_id" {
  description = "ID of the SSM security group."
  value       = module.security_groups.ssm_sg_id
}
