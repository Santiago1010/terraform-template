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

output "session_manager_document_name" {
  description = "Name of the SSM Session Manager configuration document."
  value       = module.ssm.session_manager_document_name
}

output "kong_public_ip" {
  description = "Public IP of the Kong instance. Point your DNS here."
  value       = module.kong.kong_public_ip
}

output "kong_instance_id" {
  description = "Kong EC2 instance ID. Use for SSM sessions."
  value       = module.kong.kong_instance_id
}

output "postgresql_infra_private_ip" {
  description = "Private IP of the infra PostgreSQL instance."
  value       = module.postgresql_infra.private_ip
}

output "postgresql_app_private_ip" {
  description = "Private IP of the app PostgreSQL instance."
  value       = module.postgresql_app.private_ip
}

output "redis_private_ip" {
  description = "Private IP of the Redis instance."
  value       = module.redis.private_ip
}

output "vault_private_ip" {
  description = "Private IP of the Vault instance."
  value       = module.vault.private_ip
}

output "observability_private_ip" {
  description = "Private IP of the observability instance."
  value       = module.observability.private_ip
}

output "rabbitmq_private_ip" {
  description = "Private IP of the RabbitMQ instance."
  value       = module.rabbitmq.private_ip
}

output "kafka_private_ip" {
  description = "Private IP of the Kafka instance."
  value       = module.kafka.private_ip
}

output "mongodb_private_ip" {
  description = "Private IP of the MongoDB instance."
  value       = module.mongodb.private_ip
}
