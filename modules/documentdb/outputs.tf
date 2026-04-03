output "endpoint" {
  description = "Primary endpoint for the DocumentDB cluster. Use this for write operations in your connection strings."
  value       = aws_docdb_cluster.main.endpoint
}

output "reader_endpoint" {
  description = "Reader endpoint for the DocumentDB cluster. Use this for read-only connections to distribute load."
  value       = aws_docdb_cluster.main.reader_endpoint
}

output "port" {
  description = "Port the DocumentDB cluster is listening on."
  value       = aws_docdb_cluster.main.port
}

output "security_group_id" {
  description = "ID of the DocumentDB security group. Use to grant access from additional resources."
  value       = aws_security_group.documentdb.id
}

output "cluster_id" {
  description = "ID of the DocumentDB cluster. Use for referencing in CloudWatch alarms or other AWS resources."
  value       = aws_docdb_cluster.main.id
}
