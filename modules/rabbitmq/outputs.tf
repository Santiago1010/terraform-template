output "instance_id" {
  description = "ID of the RabbitMQ EC2 instance. Used to open SSM sessions for administration."
  value       = aws_instance.rabbitmq.id
}

output "private_ip" {
  description = "Private IP of the RabbitMQ instance. Used by services to connect via AMQP."
  value       = aws_instance.rabbitmq.private_ip
}

output "sg_id" {
  description = "ID of the RabbitMQ security group. Reference this to allow access from specific services."
  value       = aws_security_group.rabbitmq.id
}

output "data_volume_id" {
  description = "ID of the EBS data volume. Useful for snapshots and backup automation."
  value       = aws_ebs_volume.rabbitmq_data.id
}
