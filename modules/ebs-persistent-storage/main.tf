locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(var.tags, {
    Name        = "${local.name_prefix}-nexus-data"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

resource "aws_ebs_volume" "this" {
  availability_zone = var.availability_zone
  type              = "gp3"
  size              = var.size
  iops              = var.iops
  throughput        = var.throughput
  encrypted         = var.encrypted
  kms_key_id        = var.kms_key_id

  tags = local.common_tags
}
