locals {
  prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "rds"
    ManagedBy   = "terraform"
    Owner       = "infra"
  }
}

resource "aws_db_subnet_group" "main" {
  name        = "${local.prefix}-rds-subnet-group"
  description = "Subnet group for the RDS instance. Spans multiple AZs for failover support."
  subnet_ids  = var.subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-rds-subnet-group"
  })
}

resource "aws_db_parameter_group" "main" {
  name        = "${local.prefix}-rds-parameter-group"
  family      = "postgres16"
  description = "Parameter group for the RDS PostgreSQL instance."

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_duration"
    value = "1"
  }

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-rds-parameter-group"
  })
}

resource "aws_security_group" "rds" {
  name        = "${local.prefix}-sg-rds"
  description = "Controls access to the RDS instance. Only allows inbound on port 5432 from within the VPC."
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow PostgreSQL connections from within the VPC."
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.internal_sg_id]
  }

  egress {
    description = "Allow all outbound traffic."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-sg-rds"
  })
}

resource "aws_db_instance" "main" {
  identifier        = "${local.prefix}-postgresql"
  engine            = "postgres"
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage

  max_allocated_storage = var.max_allocated_storage

  db_name  = "postgres"
  username = var.master_username
  password = var.master_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az                  = var.multi_az
  deletion_protection       = var.deletion_protection
  backup_retention_period   = var.backup_retention_days
  skip_final_snapshot       = false
  final_snapshot_identifier = "${local.prefix}-postgresql-final-snapshot"

  storage_encrypted = true
  storage_type      = "gp3"

  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-postgresql"
  })
}
