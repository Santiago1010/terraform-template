output "queue_urls" {
  description = "Map of queue name to queue URL. Use these URLs when configuring producers and consumers."
  value       = { for k, q in aws_sqs_queue.queues : k => q.url }
}

output "queue_arns" {
  description = "Map of queue name to queue ARN. Use these ARNs in IAM policies that grant send/receive access."
  value       = { for k, q in aws_sqs_queue.queues : k => q.arn }
}

output "deadletter_queue_urls" {
  description = "Map of queue name to its dead-letter queue URL. Useful for monitoring and manual reprocessing."
  value       = { for k, q in aws_sqs_queue.deadletter : k => q.url }
}

output "deadletter_queue_arns" {
  description = "Map of queue name to its dead-letter queue ARN. Reference in CloudWatch alarms for DLQ depth."
  value       = { for k, q in aws_sqs_queue.deadletter : k => q.arn }
}
