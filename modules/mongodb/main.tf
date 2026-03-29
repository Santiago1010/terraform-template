locals {
  prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "mongodb"
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

resource "aws_security_group" "mongodb" {
  name        = "${local.prefix}-sg-mongodb"
  description = "Controls access to MongoDB. Only allows inbound on port 27017 from within the VPC."
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow MongoDB connections from within the VPC only."
    from_port   = 27017
    to_port     = 27017
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
    Name = "${local.prefix}-sg-mongodb"
  })
}

resource "aws_instance" "mongodb" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  iam_instance_profile = var.instance_profile_name

  vpc_security_group_ids = [
    aws_security_group.mongodb.id,
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
    Name        = "${local.prefix}-mongodb-ec2"
    Environment = var.environment
  })
}

resource "aws_ebs_volume" "mongodb_data" {
  availability_zone = aws_instance.mongodb.availability_zone
  size              = var.data_volume_size
  type              = "gp3"
  encrypted         = true

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-mongodb-data-volume"
  })
}

resource "aws_volume_attachment" "mongodb_data" {
  device_name                    = "/dev/sdb"
  volume_id                      = aws_ebs_volume.mongodb_data.id
  instance_id                    = aws_instance.mongodb.id
  stop_instance_before_detaching = true
}
