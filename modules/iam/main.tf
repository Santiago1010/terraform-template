locals {
  prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "iam"
    ManagedBy   = "terraform"
    Owner       = "infra"
  }
}

resource "aws_iam_role" "ec2_base" {
  name = "${local.prefix}-ec2-base-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_base.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_base" {
  name = "${local.prefix}-ec2-base-profile"
  role = aws_iam_role.ec2_base.name

  tags = local.common_tags
}

resource "aws_iam_policy" "developer" {
  name        = "${local.prefix}-developer-policy"
  description = "Grants developers SSM access and read access to infra logs."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMSessionAccess"
        Effect = "Allow"
        Action = [
          "ssm:StartSession",
          "ssm:TerminateSession",
          "ssm:ResumeSession",
          "ssm:DescribeSessions",
          "ssm:GetConnectionStatus"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ssm:resourceTag/Environment" = var.environment
          }
        }
      },
      {
        Sid    = "SSMPortForwarding"
        Effect = "Allow"
        Action = [
          "ssm:StartSession"
        ]
        Resource = "arn:aws:ssm:us-east-1::document/AWS-StartPortForwardingSessionToRemoteHost"
      },
      {
        Sid      = "LogsReadAccess"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [var.infra_bucket_arn, "${var.infra_bucket_arn}/*"]
      },
      {
        Sid      = "EC2DescribeAccess"
        Effect   = "Allow"
        Action   = ["ec2:DescribeInstances"]
        Resource = "*"
      },
      {
        Sid    = "TerraformStateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.state_bucket_arn,
          "${var.state_bucket_arn}/*"
        ]
      },
      {
        Sid    = "TerraformLockAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:us-east-1:${var.aws_account_id}:table/terraform-locks"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "infra_admin" {
  name        = "${local.prefix}-infra-admin-policy"
  description = "Grants infra admins full SSM access and S3 state bucket access."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "SSMFullAccess"
        Effect   = "Allow"
        Action   = ["ssm:*"]
        Resource = "*"
      },
      {
        Sid      = "EC2DescribeAccess"
        Effect   = "Allow"
        Action   = ["ec2:Describe*"]
        Resource = "*"
      },
      {
        Sid      = "S3InfraFullAccess"
        Effect   = "Allow"
        Action   = ["s3:*"]
        Resource = [var.infra_bucket_arn, "${var.infra_bucket_arn}/*"]
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role" "developer" {
  name        = "${local.prefix}-developer-role"
  description = "Assumed by developers to access dev resources via SSM and read logs."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.aws_account_id}:root" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role" "infra_admin" {
  name        = "${local.prefix}-infra-admin-role"
  description = "Assumed by infra admins to manage infrastructure and access all instances."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.aws_account_id}:root" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "developer" {
  role       = aws_iam_role.developer.name
  policy_arn = aws_iam_policy.developer.arn
}

resource "aws_iam_role_policy_attachment" "infra_admin" {
  role       = aws_iam_role.infra_admin.name
  policy_arn = aws_iam_policy.infra_admin.arn
}

resource "aws_iam_policy" "assume_developer" {
  name        = "${local.prefix}-assume-developer-policy"
  description = "Allows attachment to IAM users who should assume the developer role."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AssumeDevRole"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.developer.arn
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "assume_infra_admin" {
  name        = "${local.prefix}-assume-infra-admin-policy"
  description = "Allows attachment to IAM users who should assume the infra-admin role."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AssumeInfraAdminRole"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.infra_admin.arn
      }
    ]
  })

  tags = local.common_tags
}
