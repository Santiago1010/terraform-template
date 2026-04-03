locals {
  prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "documentdb"
    ManagedBy   = "terraform"
    Owner       = "infra"
  }
}

resource "aws_docdb_subnet_group" "main" {
  name        = "${local.prefix}-docdb-subnet-group"
  description = "Subnet group for the DocumentDB cluster. Spans multiple AZs for failover support."
  subnet_ids  = var.subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-docdb-subnet-group"
  })
}

resource "aws_docdb_cluster_parameter_group" "main" {
  name        = "${local.prefix}-docdb-parameter-group"
  family      = "docdb5.0"
  description = "Parameter group for the DocumentDB cluster."

  parameter {
    name  = "tls"
    value = "enabled"
  }

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-docdb-parameter-group"
  })
}

resource "aws_security_group" "documentdb" {
  name        = "${local.prefix}-sg-documentdb"
  description = "Controls access to the DocumentDB cluster. Only allows inbound on port 27017 from within the VPC."
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow MongoDB-compatible connections from within the VPC."
    from_port       = 27017
    to_port         = 27017
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
    Name = "${local.prefix}-sg-documentdb"
  })
}

resource "aws_docdb_cluster" "main" {
  cluster_identifier              = "${local.prefix}-documentdb"
  engine                          = "docdb"
  engine_version                  = var.engine_version
  master_username                 = var.master_username
  master_password                 = var.master_password
  db_subnet_group_name            = aws_docdb_subnet_group.main.name
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.main.name
  vpc_security_group_ids          = [aws_security_group.documentdb.id]

  backup_retention_period   = var.backup_retention_days
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = "${local.prefix}-documentdb-final-snapshot"

  storage_encrypted = true

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-documentdb"
  })
}

resource "aws_docdb_cluster_instance" "main" {
  count              = var.instance_count
  identifier         = "${local.prefix}-documentdb-${count.index}"
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = var.instance_class

  auto_minor_version_upgrade = true

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-documentdb-${count.index}"
  })
}
