locals {
  prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "vault"
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

resource "aws_security_group" "vault" {
  name        = "${local.prefix}-sg-vault"
  description = "Controls access to Vault. Allows API access on 8200 and cluster traffic on 8201 from within the VPC."
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow Vault API access from within the VPC."
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.current.cidr_block]
  }

  ingress {
    description = "Allow Vault cluster communication for HA and Raft replication."
    from_port   = 8201
    to_port     = 8201
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
    Name = "${local.prefix}-sg-vault"
  })
}

resource "aws_instance" "vault" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  iam_instance_profile = var.instance_profile_name

  vpc_security_group_ids = [
    aws_security_group.vault.id,
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
    Name        = "${local.prefix}-vault-ec2"
    Environment = var.environment
  })
}

resource "aws_ebs_volume" "vault_data" {
  availability_zone = aws_instance.vault.availability_zone
  size              = var.data_volume_size
  type              = "gp3"
  encrypted         = true

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-vault-data-volume"
  })
}

resource "aws_volume_attachment" "vault_data" {
  device_name                    = "/dev/sdb"
  volume_id                      = aws_ebs_volume.vault_data.id
  instance_id                    = aws_instance.vault.id
  stop_instance_before_detaching = true
}
