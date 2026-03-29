locals {
  prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "observability"
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

resource "aws_security_group" "observability" {
  name        = "${local.prefix}-sg-observability"
  description = "Controls access to the observability stack. Allows Grafana UI and Prometheus from within the VPC."
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow Grafana UI access from within the VPC."
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.current.cidr_block]
  }

  ingress {
    description = "Allow Prometheus UI and API access from within the VPC."
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.current.cidr_block]
  }

  ingress {
    description = "Allow Loki log ingestion from within the VPC."
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.current.cidr_block]
  }

  ingress {
    description = "Allow Tempo trace ingestion from within the VPC."
    from_port   = 4317
    to_port     = 4317
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
    Name = "${local.prefix}-sg-observability"
  })
}

resource "aws_instance" "observability" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  iam_instance_profile = var.instance_profile_name

  vpc_security_group_ids = [
    aws_security_group.observability.id,
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
    Name        = "${local.prefix}-observability-ec2"
    Environment = var.environment
  })
}

resource "aws_ebs_volume" "observability_data" {
  availability_zone = aws_instance.observability.availability_zone
  size              = var.data_volume_size
  type              = "gp3"
  encrypted         = true

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-observability-data-volume"
  })
}

resource "aws_volume_attachment" "observability_data" {
  device_name                    = "/dev/sdb"
  volume_id                      = aws_ebs_volume.observability_data.id
  instance_id                    = aws_instance.observability.id
  stop_instance_before_detaching = true
}
