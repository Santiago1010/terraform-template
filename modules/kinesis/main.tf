locals {
  prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "kinesis"
    ManagedBy   = "terraform"
    Owner       = "infra"
  }
}

resource "aws_kinesis_stream" "streams" {
  for_each = var.streams

  name             = "${local.prefix}-${each.key}"
  retention_period = each.value.retention_hours
  shard_count      = each.value.stream_mode == "PROVISIONED" ? each.value.shard_count : null

  stream_mode_details {
    stream_mode = each.value.stream_mode
  }

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-${each.key}"
  })
}
