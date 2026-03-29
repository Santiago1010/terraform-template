output "instance_id" {
  description = "ID of the PostgreSQL EC2 instance. Used to open SSM sessions for administration."
  value       = aws_instance.postgresql.id
}

output "private_ip" {
  description = "Private IP of the PostgreSQL instance. Used by services to connect to the database."
  value       = aws_instance.postgresql.private_ip
}

output "sg_id" {
  description = "ID of the PostgreSQL security group. Reference this to allow access from specific services."
  value       = aws_security_group.postgresql.id
}

output "data_volume_id" {
  description = "ID of the EBS data volume. Useful for snapshots and backup automation."
  value       = aws_ebs_volume.postgresql_data.id
}
