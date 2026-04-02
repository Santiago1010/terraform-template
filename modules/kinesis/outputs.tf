output "stream_arns" {
  description = "Map of stream name to stream ARN. Use in IAM policies that grant producers and consumers access."
  value       = { for k, s in aws_kinesis_stream.streams : k => s.arn }
}

output "stream_names" {
  description = "Map of stream name to stream name. Use when configuring producers and consumers."
  value       = { for k, s in aws_kinesis_stream.streams : k => s.name }
}
