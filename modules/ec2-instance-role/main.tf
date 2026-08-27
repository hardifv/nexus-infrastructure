locals {
  name_prefix        = "${var.project_name}-${var.environment}"
  role_name          = "${local.name_prefix}-nexus-ec2"
  secret_policy_name = "${local.name_prefix}-nexus-secret-access"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(local.common_tags, {
    Name = local.role_name
  })
}

resource "aws_iam_instance_profile" "this" {
  name = local.role_name
  role = aws_iam_role.this.name

  tags = merge(local.common_tags, {
    Name = local.role_name
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
}

data "aws_iam_policy_document" "secret_access" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
    ]
    resources = [var.master_user_secret_arn]
  }
}

resource "aws_iam_policy" "secret_access" {
  name        = local.secret_policy_name
  description = "Read-only access to the Nexus RDS-managed master user secret."
  policy      = data.aws_iam_policy_document.secret_access.json

  tags = merge(local.common_tags, {
    Name = local.secret_policy_name
  })
}

resource "aws_iam_role_policy_attachment" "secret_access" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.secret_access.arn
}
