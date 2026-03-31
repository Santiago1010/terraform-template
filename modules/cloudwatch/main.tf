locals {
  prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "cloudwatch"
    ManagedBy   = "terraform"
    Owner       = "infra"
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_dlq_depth" {
  for_each = var.sqs_queue_names

  alarm_name          = "${local.prefix}-${each.key}-dlq-depth"
  alarm_description   = "DLQ ${each.value} has messages. Something is failing silently."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = var.period_seconds
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = each.value
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-${each.key}-dlq-depth"
  })
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_credit_balance" {
  for_each = var.ec2_instance_ids

  alarm_name          = "${local.prefix}-${each.key}-cpu-credit-balance"
  alarm_description   = "EC2 instance ${each.key} is running low on CPU credits. Performance will be throttled soon."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "CPUCreditBalance"
  namespace           = "AWS/EC2"
  period              = var.period_seconds
  statistic           = "Minimum"
  threshold           = var.cpu_credit_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = each.value
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-${each.key}-cpu-credit-balance"
  })
}

resource "aws_cloudwatch_metric_alarm" "ec2_status_check" {
  for_each = var.ec2_instance_ids

  alarm_name          = "${local.prefix}-${each.key}-status-check"
  alarm_description   = "EC2 instance ${each.key} failed a status check. The instance may be unreachable."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = each.value
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-${each.key}-status-check"
  })
}
