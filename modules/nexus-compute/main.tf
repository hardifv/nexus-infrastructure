locals {
  name = "${var.project_name}-${var.environment}-nexus"

  common_tags = merge(var.tags, {
    Name        = local.name
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

resource "aws_launch_template" "this" {
  name                   = local.name
  image_id               = var.ami_id
  instance_type          = var.instance_type
  ebs_optimized          = true
  update_default_version = true

  iam_instance_profile {
    name = var.instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    device_index                = 0
    security_groups             = sort(tolist(var.security_group_ids))
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
    instance_metadata_tags      = "disabled"
  }

  monitoring {
    enabled = var.detailed_monitoring_enabled
  }

  block_device_mappings {
    device_name = var.root_device_name

    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.common_tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(local.common_tags, { Name = "${local.name}-root" })
  }

  tags = local.common_tags
}

resource "aws_instance" "this" {
  # checkov:skip=CKV_AWS_79:The EC2 instance inherits required IMDSv2 configuration from aws_launch_template.this.
  # checkov:skip=CKV_AWS_135:The EC2 instance inherits ebs_optimized = true from the Launch Template.
  # checkov:skip=CKV_AWS_8:The EC2 root volume inherits encryption from the Launch Template block device configuration.
  # checkov:skip=CKV_AWS_126:Detailed monitoring is intentionally disabled by default for the dev cost baseline and remains configurable for later environments and the monitoring checkpoint.
  # checkov:skip=CKV2_AWS_41:The EC2 instance inherits its IAM instance profile from aws_launch_template.this.
  subnet_id                   = var.subnet_id
  associate_public_ip_address = false

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}
