locals {
  prefix = "/${var.project}/${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "ssm-parameters"
    ManagedBy   = "terraform"
    Owner       = "infra"
  }
}

resource "aws_ssm_parameter" "parameters" {
  for_each = var.parameters

  name        = "${local.prefix}/${each.key}"
  description = each.value.description
  value       = each.value.value
  type        = each.value.type
  tier        = each.value.tier

  tags = merge(local.common_tags, {
    Name = "${local.prefix}/${each.key}"
  })

  lifecycle {
    ignore_changes = [value]
  }
}
