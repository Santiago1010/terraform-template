output "kong_instance_id" {
  description = "ID of the Kong EC2 instance. Used to open SSM sessions for administration."
  value       = aws_instance.kong.id
}

output "kong_public_ip" {
  description = "Elastic IP address of the Kong instance. Use this for DNS records."
  value       = aws_eip.kong.public_ip
}

output "kong_private_ip" {
  description = "Private IP of the Kong instance. Used for internal service-to-service communication."
  value       = aws_instance.kong.private_ip
}

output "kong_sg_id" {
  description = "ID of the Kong security group. Useful for referencing in other security group rules."
  value       = aws_security_group.kong.id
}
