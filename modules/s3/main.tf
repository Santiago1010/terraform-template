locals {
  prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "s3"
    ManagedBy   = "terraform"
    Owner       = "infra"
  }
}

resource "aws_s3_bucket" "infra" {
  bucket = "${local.prefix}-infra"

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-infra"
  })
}

resource "aws_s3_bucket_versioning" "infra" {
  bucket = aws_s3_bucket.infra.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "infra" {
  bucket = aws_s3_bucket.infra.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "infra" {
  bucket = aws_s3_bucket.infra.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "infra" {
  bucket = aws_s3_bucket.infra.id

  rule {
    id     = "ssm-logs-retention"
    status = "Enabled"

    filter {
      prefix = "ssm-logs/"
    }

    expiration {
      days = var.logs_retention_days
    }
  }

  rule {
    id     = "backups-retention"
    status = "Enabled"

    filter {
      prefix = "backups/"
    }

    expiration {
      days = var.backups_retention_days
    }
  }
}

resource "aws_s3_bucket_policy" "infra" {
  bucket = aws_s3_bucket.infra.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMLogsWrite"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
        Action = [
          "s3:PutObject",
          "s3:GetEncryptionConfiguration"
        ]
        Resource = [
          "${aws_s3_bucket.infra.arn}/ssm-logs/*",
          aws_s3_bucket.infra.arn
        ]
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.aws_account_id
          }
        }
      }
    ]
  })
}
