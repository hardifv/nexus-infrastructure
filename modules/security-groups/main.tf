locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

resource "aws_security_group" "alb" {
  #checkov:skip=CKV2_AWS_5:The reusable module intentionally creates Security Groups separately; attachment is performed by ALB, EC2, and RDS consumer modules.
  name        = "${local.name_prefix}-alb-sg"
  description = "Controls traffic for the Application Load Balancer."
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-sg"
  })
}

resource "aws_security_group" "nexus" {
  #checkov:skip=CKV2_AWS_5:The reusable module intentionally creates Security Groups separately; attachment is performed by ALB, EC2, and RDS consumer modules.
  name        = "${local.name_prefix}-nexus-sg"
  description = "Controls traffic for the Nexus EC2 instance."
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nexus-sg"
  })
}

resource "aws_security_group" "rds" {
  #checkov:skip=CKV2_AWS_5:The reusable module intentionally creates Security Groups separately; attachment is performed by ALB, EC2, and RDS consumer modules.
  name        = "${local.name_prefix}-rds-sg"
  description = "Controls traffic for the RDS PostgreSQL database."
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = var.allowed_client_cidrs

  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from an approved client network."
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-http-${replace(each.value, "/", "-")}"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each = var.allowed_client_cidrs

  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from an approved client network."
  cidr_ipv4         = each.value
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-https-${replace(each.value, "/", "-")}"
  })
}

resource "aws_vpc_security_group_egress_rule" "alb_to_nexus" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward Nexus application traffic to the EC2 instance."
  referenced_security_group_id = aws_security_group.nexus.id
  from_port                    = var.nexus_port
  to_port                      = var.nexus_port
  ip_protocol                  = "tcp"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-to-nexus"
  })
}

resource "aws_vpc_security_group_ingress_rule" "nexus_from_alb" {
  security_group_id            = aws_security_group.nexus.id
  description                  = "Accept Nexus application traffic only from the ALB."
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.nexus_port
  to_port                      = var.nexus_port
  ip_protocol                  = "tcp"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nexus-from-alb"
  })
}

resource "aws_vpc_security_group_egress_rule" "nexus_http" {
  security_group_id = aws_security_group.nexus.id
  description       = "Allow HTTP downloads from package and image repositories."
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nexus-http-egress"
  })
}

resource "aws_vpc_security_group_egress_rule" "nexus_https" {
  security_group_id = aws_security_group.nexus.id
  description       = "Allow HTTPS downloads from package and image repositories."
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nexus-https-egress"
  })
}

resource "aws_vpc_security_group_egress_rule" "nexus_dns_tcp" {
  security_group_id = aws_security_group.nexus.id
  description       = "Allow DNS over TCP within the VPC."
  cidr_ipv4         = var.vpc_cidr
  from_port         = 53
  to_port           = 53
  ip_protocol       = "tcp"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nexus-dns-tcp"
  })
}

resource "aws_vpc_security_group_egress_rule" "nexus_dns_udp" {
  security_group_id = aws_security_group.nexus.id
  description       = "Allow DNS over UDP within the VPC."
  cidr_ipv4         = var.vpc_cidr
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nexus-dns-udp"
  })
}

resource "aws_vpc_security_group_egress_rule" "nexus_to_rds" {
  security_group_id            = aws_security_group.nexus.id
  description                  = "Allow PostgreSQL traffic from Nexus to RDS."
  referenced_security_group_id = aws_security_group.rds.id
  from_port                    = var.database_port
  to_port                      = var.database_port
  ip_protocol                  = "tcp"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nexus-to-rds"
  })
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_nexus" {
  security_group_id            = aws_security_group.rds.id
  description                  = "Accept PostgreSQL traffic only from Nexus."
  referenced_security_group_id = aws_security_group.nexus.id
  from_port                    = var.database_port
  to_port                      = var.database_port
  ip_protocol                  = "tcp"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds-from-nexus"
  })
}
