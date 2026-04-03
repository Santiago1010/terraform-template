locals {
  prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Service     = "elasticache"
    ManagedBy   = "terraform"
    Owner       = "infra"
  }
}

resource "aws_elasticache_subnet_group" "main" {
  name        = "${local.prefix}-elasticache-subnet-group"
  description = "Subnet group for the ElastiCache cluster. Spans multiple AZs for failover support."
  subnet_ids  = var.subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-elasticache-subnet-group"
  })
}

resource "aws_elasticache_parameter_group" "main" {
  name        = "${local.prefix}-elasticache-parameter-group"
  family      = "redis7"
  description = "Parameter group for the ElastiCache Redis cluster."

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-elasticache-parameter-group"
  })
}

resource "aws_security_group" "elasticache" {
  name        = "${local.prefix}-sg-elasticache"
  description = "Controls access to the ElastiCache cluster. Only allows inbound on port 6379 from within the VPC."
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow Redis connections from within the VPC."
    from_port       = 6379
    to_port         = 6379
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
    Name = "${local.prefix}-sg-elasticache"
  })
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${local.prefix}-redis"
  description          = "Redis replication group for ${var.project} ${var.environment}."

  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_clusters   = var.num_cache_nodes
  parameter_group_name = aws_elasticache_parameter_group.main.name
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.elasticache.id]

  automatic_failover_enabled = var.automatic_failover
  at_rest_encryption_enabled = var.at_rest_encryption
  transit_encryption_enabled = var.transit_encryption
  auth_token                 = var.transit_encryption ? var.auth_token : null

  snapshot_retention_limit = var.snapshot_retention_days

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-redis"
  })
}
