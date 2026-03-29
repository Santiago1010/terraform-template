output "instance_id" {
  description = "ID of the MongoDB EC2 instance. Used to open SSM sessions for administration."
  value       = aws_instance.mongodb.id
}

output "private_ip" {
  description = "Private IP of the MongoDB instance. Used by services to connect to the database."
  value       = aws_instance.mongodb.private_ip
}

output "sg_id" {
  description = "ID of the MongoDB security group. Reference this to allow access from specific services."
  value       = aws_security_group.mongodb.id
}

output "data_volume_id" {
  description = "ID of the EBS data volume. Useful for snapshots and backup automation."
  value       = aws_ebs_volume.mongodb_data.id
}
