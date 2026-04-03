output "primary_endpoint" {
  description = "Primary endpoint for the ElastiCache replication group. Use this as the hostname in your Redis connection strings."
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "reader_endpoint" {
  description = "Reader endpoint for the ElastiCache replication group. Use this for read-only connections to distribute load."
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

output "port" {
  description = "Port the ElastiCache cluster is listening on."
  value       = aws_elasticache_replication_group.main.port
}

output "security_group_id" {
  description = "ID of the ElastiCache security group. Use to grant access from additional resources."
  value       = aws_security_group.elasticache.id
}

output "replication_group_id" {
  description = "ID of the ElastiCache replication group. Use for referencing in CloudWatch alarms or other AWS resources."
  value       = aws_elasticache_replication_group.main.id
}
