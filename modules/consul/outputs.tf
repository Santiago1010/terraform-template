output "instance_id" {
  description = "ID of the Consul EC2 instance. Used to open SSM sessions for administration."
  value       = aws_instance.consul.id
}

output "private_ip" {
  description = "Private IP of the Consul instance. Used by services to register and query the service catalog."
  value       = aws_instance.consul.private_ip
}

output "sg_id" {
  description = "ID of the Consul security group. Reference this to allow access from specific services."
  value       = aws_security_group.consul.id
}
