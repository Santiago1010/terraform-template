locals {
  prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "consul"
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

resource "aws_security_group" "consul" {
  name        = "${local.prefix}-sg-consul"
  description = "Controls access to Consul. Allows HTTP API, DNS, and gossip protocol from within the VPC."
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow Consul HTTP API and UI access from within the VPC."
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.current.cidr_block]
  }

  ingress {
    description = "Allow Consul DNS interface from within the VPC."
    from_port   = 8600
    to_port     = 8600
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.current.cidr_block]
  }

  ingress {
    description = "Allow Consul DNS over UDP from within the VPC."
    from_port   = 8600
    to_port     = 8600
    protocol    = "udp"
    cidr_blocks = [data.aws_vpc.current.cidr_block]
  }

  ingress {
    description = "Allow Consul gossip protocol TCP from within the VPC."
    from_port   = 8301
    to_port     = 8301
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.current.cidr_block]
  }

  ingress {
    description = "Allow Consul gossip protocol UDP from within the VPC."
    from_port   = 8301
    to_port     = 8301
    protocol    = "udp"
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
    Name = "${local.prefix}-sg-consul"
  })
}

resource "aws_instance" "consul" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  iam_instance_profile = var.instance_profile_name

  vpc_security_group_ids = [
    aws_security_group.consul.id,
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
    Name        = "${local.prefix}-consul-ec2"
    Environment = var.environment
  })
}
