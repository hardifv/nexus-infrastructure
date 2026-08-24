locals {
  name_prefix   = "${var.project_name}-${var.environment}"
  db_identifier = "${local.name_prefix}-postgresql"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-rds-subnets"
  subnet_ids = var.private_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds-subnets"
  })
}

resource "aws_db_instance" "this" {
  #checkov:skip=CKV2_AWS_30: PostgreSQL query logging requires a dedicated parameter group and is deferred to the monitoring checkpoint to define safe logging, retention, and CloudWatch export.
  # checkov:skip=CKV_AWS_161:JDBC username/password authentication is the accepted dev integration; IAM DB authentication is out of scope.
  # checkov:skip=CKV_AWS_293:Deletion protection is intentionally disabled in dev to support controlled teardown.
  # checkov:skip=CKV_AWS_353:Performance Insights is deferred to the dedicated monitoring checkpoint.
  # checkov:skip=CKV_AWS_157:Single-AZ is the accepted cost-conscious dev topology.
  # checkov:skip=CKV_AWS_129:RDS log exports are deferred to the dedicated monitoring checkpoint.
  # checkov:skip=CKV_AWS_118:Enhanced Monitoring is deferred to the dedicated monitoring checkpoint.
  identifier = local.db_identifier

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class
  db_name        = var.database_name
  username       = var.master_username
  port           = var.port

  manage_master_user_password         = true
  iam_database_authentication_enabled = false

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_security_group_id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  backup_retention_period    = var.backup_retention_period
  copy_tags_to_snapshot      = true
  delete_automated_backups   = false
  auto_minor_version_upgrade = true

  deletion_protection       = var.deletion_protection_enabled
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.db_identifier}-final"
  apply_immediately         = var.apply_immediately

  tags = merge(local.common_tags, {
    Name = local.db_identifier
  })
}
