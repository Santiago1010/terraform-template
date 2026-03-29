locals {
  prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "security-groups"
    ManagedBy   = "terraform"
    Owner       = "infra"
  }
}

resource "aws_security_group" "internal" {
  name        = "${local.prefix}-sg-internal"
  description = "Allows unrestricted traffic between all resources inside the VPC."
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow all inbound traffic from within the VPC."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-sg-internal"
  })
}

resource "aws_security_group" "ssm" {
  name        = "${local.prefix}-sg-ssm"
  description = "Allows outbound HTTPS traffic required by the SSM agent to communicate with AWS."
  vpc_id      = var.vpc_id

  egress {
    description = "Allow outbound HTTPS so the SSM agent can reach AWS service endpoints."
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-sg-ssm"
  })
}
