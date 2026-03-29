output "instance_id" {
  description = "ID of the Redis EC2 instance. Used to open SSM sessions for administration."
  value       = aws_instance.redis.id
}

output "private_ip" {
  description = "Private IP of the Redis instance. Used by services to connect to Redis."
  value       = aws_instance.redis.private_ip
}

output "sg_id" {
  description = "ID of the Redis security group. Reference this to allow access from specific services."
  value       = aws_security_group.redis.id
}
