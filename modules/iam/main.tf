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
