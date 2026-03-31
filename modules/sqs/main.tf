locals {
  prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "sqs"
    ManagedBy   = "terraform"
    Owner       = "infra"
  }
}

resource "aws_sqs_queue" "queues" {
  for_each = var.queues

  name                       = "${local.prefix}-${each.key}"
  delay_seconds              = each.value.delay_seconds
  message_retention_seconds  = each.value.message_retention_seconds
  visibility_timeout_seconds = each.value.visibility_timeout_seconds
  receive_wait_time_seconds  = each.value.receive_wait_time_seconds

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-${each.key}"
  })
}

resource "aws_sqs_queue" "deadletter" {
  for_each = var.queues

  name                      = "${local.prefix}-${each.key}-dlq"
  message_retention_seconds = 1209600

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-${each.key}-dlq"
  })
}

resource "aws_sqs_queue_redrive_policy" "queues" {
  for_each = var.queues

  queue_url = aws_sqs_queue.queues[each.key].url
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.deadletter[each.key].arn
    maxReceiveCount     = 3
  })
}
