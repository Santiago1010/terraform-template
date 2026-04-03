output "endpoint" {
  description = "Connection endpoint for the RDS instance. Use this as the hostname in your database connection strings."
  value       = aws_db_instance.main.endpoint
}

output "port" {
  description = "Port the RDS instance is listening on."
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Name of the default database created on the RDS instance."
  value       = aws_db_instance.main.db_name
}

output "security_group_id" {
  description = "ID of the RDS security group. Use to grant access from additional resources."
  value       = aws_security_group.rds.id
}

output "instance_id" {
  description = "Identifier of the RDS instance. Use for referencing in CloudWatch alarms or other AWS resources."
  value       = aws_db_instance.main.id
}
