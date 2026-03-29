locals {
  prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "ssm"
    ManagedBy   = "terraform"
    Owner       = "infra"
  }
}

resource "aws_ssm_document" "session_manager" {
  name            = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Session Manager default shell configuration"
    sessionType   = "Standard_Shell"
    inputs = {
      idleSessionTimeout  = tostring(var.session_timeout_minutes)
      maxSessionDuration  = tostring(var.session_timeout_minutes * 2)
      runAsEnabled        = false
      s3BucketName        = regex("arn:aws:s3:::(.+)", var.logs_bucket_arn)[0]
      s3KeyPrefix         = "ssm-logs"
      s3EncryptionEnabled = true
      shellProfile = {
        linux = ""
      }
    }
  })

  tags = local.common_tags
}
