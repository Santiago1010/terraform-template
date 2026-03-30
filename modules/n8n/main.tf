locals {
  prefix = "${var.project}-${var.environment}-n8n-${var.name}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "n8n-${var.name}"
    ManagedBy   = "terraform"
    Owner       = "infra"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "current" {
  id = var.vpc_id
}

resource "aws_security_group" "n8n" {
  name        = "${local.prefix}-sg"
  description = "Controls access to n8n-${var.name}. Allows UI and webhook access from within the VPC."
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow n8n UI and API access from within the VPC."
    from_port   = 5678
    to_port     = 5678
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.current.cidr_block]
  }

  egress {
    description = "Allow all outbound traffic."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-sg"
  })
}

resource "aws_instance" "n8n" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  iam_instance_profile = var.instance_profile_name

  vpc_security_group_ids = [
    aws_security_group.n8n.id,
    var.internal_sg_id,
    var.ssm_sg_id,
  ]

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name        = "${local.prefix}-ec2"
    Environment = var.environment
  })
}
