output "instance_id" {
  description = "ID of the observability EC2 instance. Used to open SSM sessions for administration."
  value       = aws_instance.observability.id
}

output "private_ip" {
  description = "Private IP of the observability instance. Used to access Grafana and Prometheus internally."
  value       = aws_instance.observability.private_ip
}

output "sg_id" {
  description = "ID of the observability security group. Reference this to allow scraping from specific services."
  value       = aws_security_group.observability.id
}

output "data_volume_id" {
  description = "ID of the EBS data volume. Useful for snapshots and backup automation."
  value       = aws_ebs_volume.observability_data.id
}
