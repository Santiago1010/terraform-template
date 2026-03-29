output "instance_id" {
  description = "ID of the Kafka EC2 instance. Used to open SSM sessions for administration."
  value       = aws_instance.kafka.id
}

output "private_ip" {
  description = "Private IP of the Kafka instance. Used by producers and consumers to connect to the broker."
  value       = aws_instance.kafka.private_ip
}

output "sg_id" {
  description = "ID of the Kafka security group. Reference this to allow access from specific services."
  value       = aws_security_group.kafka.id
}

output "data_volume_id" {
  description = "ID of the EBS data volume. Useful for snapshots and backup automation."
  value       = aws_ebs_volume.kafka_data.id
}
