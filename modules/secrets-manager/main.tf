locals {
  prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "secrets-manager"
    ManagedBy   = "terraform"
    Owner       = "infra"
  }
}

resource "aws_secretsmanager_secret" "secrets" {
  for_each = var.secrets

  name                    = "${local.prefix}/${each.key}"
  description             = each.value.description
  recovery_window_in_days = each.value.recovery_window

  tags = merge(local.common_tags, {
    Name = "${local.prefix}/${each.key}"
  })
}

resource "aws_secretsmanager_secret_version" "secrets" {
  for_each = nonsensitive(toset([
    for k, v in var.secrets : k
    if v.initial_value != null
  ]))

  secret_id     = aws_secretsmanager_secret.secrets[each.key].id
  secret_string = var.secrets[each.key].initial_value

  lifecycle {
    ignore_changes = [secret_string]
  }
}
