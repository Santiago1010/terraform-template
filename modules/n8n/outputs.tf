output "instance_id" {
  description = "ID of the n8n EC2 instance. Used to open SSM sessions for administration."
  value       = aws_instance.n8n.id
}

output "private_ip" {
  description = "Private IP of the n8n instance. Used to access the UI via SSM port forwarding."
  value       = aws_instance.n8n.private_ip
}

output "sg_id" {
  description = "ID of the n8n security group. Reference this to allow access from specific services."
  value       = aws_security_group.n8n.id
}
