locals {
  normalized_name = trim(replace(lower("${var.project_name}-${var.environment}"), "/[^a-z0-9-]/", "-"), "-")
  name_prefix     = substr(local.normalized_name, 0, 23)

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

resource "aws_lb" "this" {
  #checkov:skip=CKV_AWS_91:Access logging is deferred until the dedicated logging and retention checkpoint.
  #checkov:skip=CKV_AWS_150:Deletion protection is intentionally disabled by default for dev and remains configurable.
  #checkov:skip=CKV2_AWS_20:HTTP-to-HTTPS redirect depends on the future ACM and HTTPS listener.
  #checkov:skip=CKV2_AWS_28:WAF integration is deferred to the production security-hardening checkpoint.
  name                       = "${local.name_prefix}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.alb_security_group_id]
  subnets                    = var.public_subnet_ids
  enable_deletion_protection = var.deletion_protection_enabled
  drop_invalid_header_fields = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb"
  })
}

resource "aws_lb_target_group" "nexus" {
  #checkov:skip=CKV_AWS_378:HTTP between the ALB and Nexus is intentional because TLS will terminate at the ALB.
  name        = "${local.name_prefix}-nexus-tg"
  port        = var.nexus_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nexus-tg"
  })
}

resource "aws_lb_listener" "http" {
  #checkov:skip=CKV_AWS_2:HTTPS is deferred until the ACM and HTTPS listener checkpoint.
  #checkov:skip=CKV_AWS_103:TLS policy configuration depends on the future HTTPS listener.
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nexus.arn
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-http-listener"
  })
}
