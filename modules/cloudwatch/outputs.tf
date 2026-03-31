output "sqs_dlq_depth_alarm_arns" {
  description = "Map of queue name to DLQ depth alarm ARN. Useful for referencing alarms in dashboards or composite alarms."
  value       = { for k, a in aws_cloudwatch_metric_alarm.sqs_dlq_depth : k => a.arn }
}

output "ec2_cpu_credit_alarm_arns" {
  description = "Map of instance name to CPU credit balance alarm ARN."
  value       = { for k, a in aws_cloudwatch_metric_alarm.ec2_cpu_credit_balance : k => a.arn }
}

output "ec2_status_check_alarm_arns" {
  description = "Map of instance name to status check alarm ARN."
  value       = { for k, a in aws_cloudwatch_metric_alarm.ec2_status_check : k => a.arn }
}
