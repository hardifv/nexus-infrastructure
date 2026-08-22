locals {
  oidc_url       = "https://token.actions.githubusercontent.com"
  oidc_claim_key = "token.actions.githubusercontent.com"

  github_repository_parts             = split("/", var.github_repository)
  immutable_repository_subject_prefix = "repo:${local.github_repository_parts[0]}@${var.github_owner_id}/${local.github_repository_parts[1]}@${var.github_repository_id}"

  plan_role_name  = "${var.project_name}-terraform-plan"
  apply_role_name = "${var.project_name}-terraform-${var.environment_name}-apply"

  load_balancer_name_prefix = substr(trim(replace(lower("${var.managed_project_name}-${var.environment_name}"), "/[^a-z0-9-]/", "-"), "-"), 0, 23)
  load_balancer_arn_pattern = "arn:*:elasticloadbalancing:${var.aws_region}:*:loadbalancer/app/${local.load_balancer_name_prefix}-alb/*"
  target_group_arn_pattern  = "arn:*:elasticloadbalancing:${var.aws_region}:*:targetgroup/${local.load_balancer_name_prefix}-nexus-tg/*"
  http_listener_arn_pattern = "arn:*:elasticloadbalancing:${var.aws_region}:*:listener/app/${local.load_balancer_name_prefix}-alb/*/*"

  common_tags = merge(var.tags, {
    Project   = var.project_name
    ManagedBy = "Terraform"
  })
}

data "aws_iam_openid_connect_provider" "github" {
  url = local.oidc_url
}

data "aws_iam_policy_document" "terraform_plan_assume_role" {
  statement {
    sid     = "GitHubPullRequestPlans"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_claim_key}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_claim_key}:sub"
      values   = ["${local.immutable_repository_subject_prefix}:pull_request"]
    }
  }
}

resource "aws_iam_role" "terraform_plan" {
  name               = local.plan_role_name
  assume_role_policy = data.aws_iam_policy_document.terraform_plan_assume_role.json

  tags = merge(local.common_tags, {
    Name = local.plan_role_name
  })
}

data "aws_iam_policy_document" "terraform_apply_assume_role" {
  statement {
    sid     = "GitHubEnvironmentApply"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_claim_key}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_claim_key}:sub"
      values   = ["${local.immutable_repository_subject_prefix}:environment:${var.environment_name}"]
    }
  }
}

resource "aws_iam_role" "terraform_apply" {
  name               = local.apply_role_name
  assume_role_policy = data.aws_iam_policy_document.terraform_apply_assume_role.json

  tags = merge(local.common_tags, {
    Name = local.apply_role_name
  })
}

data "aws_iam_policy_document" "terraform_plan_permissions" {
  statement {
    sid       = "ListStateAndLockKeys"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.state_bucket_arn]

    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values = [
        var.state_key,
        "${var.state_key}.tflock",
      ]
    }
  }

  statement {
    sid       = "ReadTerraformState"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${var.state_bucket_arn}/${var.state_key}"]
  }

  statement {
    sid    = "ManageTerraformLockFile"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["${var.state_bucket_arn}/${var.state_key}.tflock"]
  }

  statement {
    sid       = "DescribeEC2NetworkResources"
    effect    = "Allow"
    actions   = ["ec2:Describe*"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid    = "DescribeLoadBalancerResources"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DescribeListenerAttributes",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetGroups",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }
}

resource "aws_iam_policy" "terraform_plan" {
  name        = "${local.plan_role_name}-permissions"
  description = "Permissions for Terraform pull-request plans."
  policy      = data.aws_iam_policy_document.terraform_plan_permissions.json

  tags = merge(local.common_tags, {
    Name = "${local.plan_role_name}-permissions"
  })
}

resource "aws_iam_role_policy_attachment" "terraform_plan" {
  role       = aws_iam_role.terraform_plan.name
  policy_arn = aws_iam_policy.terraform_plan.arn
}

data "aws_iam_policy_document" "terraform_apply_permissions" {
  statement {
    sid       = "ListStateAndLockKeys"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.state_bucket_arn]

    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values = [
        var.state_key,
        "${var.state_key}.tflock",
      ]
    }
  }

  statement {
    sid    = "ReadAndWriteTerraformState"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["${var.state_bucket_arn}/${var.state_key}"]
  }

  statement {
    sid    = "ManageTerraformLockFile"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["${var.state_bucket_arn}/${var.state_key}.tflock"]
  }

  statement {
    sid       = "DescribeEC2NetworkResources"
    effect    = "Allow"
    actions   = ["ec2:Describe*"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid    = "DescribeLoadBalancerResources"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DescribeListenerAttributes",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetGroups",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid    = "CreateLoadBalancerResources"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid       = "TagApplicationLoadBalancerOnCreate"
    effect    = "Allow"
    actions   = ["elasticloadbalancing:AddTags"]
    resources = [local.load_balancer_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringEquals"
      variable = "elasticloadbalancing:CreateAction"
      values   = ["CreateLoadBalancer"]
    }
  }

  statement {
    sid       = "TagNexusTargetGroupOnCreate"
    effect    = "Allow"
    actions   = ["elasticloadbalancing:AddTags"]
    resources = [local.target_group_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringEquals"
      variable = "elasticloadbalancing:CreateAction"
      values   = ["CreateTargetGroup"]
    }
  }

  statement {
    sid       = "TagHTTPListenerOnCreate"
    effect    = "Allow"
    actions   = ["elasticloadbalancing:AddTags"]
    resources = [local.http_listener_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringEquals"
      variable = "elasticloadbalancing:CreateAction"
      values   = ["CreateListener"]
    }
  }

  statement {
    sid    = "ManageApplicationLoadBalancer"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
    ]
    resources = [local.load_balancer_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid    = "ManageNexusTargetGroup"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:RemoveTags",
    ]
    resources = [local.target_group_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid    = "ManageHTTPListener"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:RemoveTags",
    ]
    resources = [local.http_listener_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid    = "ManageDevNetworkResources"
    effect = "Allow"
    actions = [
      "ec2:AllocateAddress",
      "ec2:AssociateRouteTable",
      "ec2:AttachInternetGateway",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateInternetGateway",
      "ec2:CreateNatGateway",
      "ec2:CreateRoute",
      "ec2:CreateRouteTable",
      "ec2:CreateSecurityGroup",
      "ec2:CreateSubnet",
      "ec2:CreateTags",
      "ec2:CreateVpc",
      "ec2:DeleteInternetGateway",
      "ec2:DeleteNatGateway",
      "ec2:DeleteRoute",
      "ec2:DeleteRouteTable",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteSubnet",
      "ec2:DeleteTags",
      "ec2:DeleteVpc",
      "ec2:DetachInternetGateway",
      "ec2:DisassociateRouteTable",
      "ec2:ModifySecurityGroupRules",
      "ec2:ModifySubnetAttribute",
      "ec2:ModifyVpcAttribute",
      "ec2:ReleaseAddress",
      "ec2:ReplaceRoute",
      "ec2:ReplaceRouteTableAssociation",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:UpdateSecurityGroupRuleDescriptionsEgress",
      "ec2:UpdateSecurityGroupRuleDescriptionsIngress",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }
}

resource "aws_iam_policy" "terraform_apply" {
  name        = "${local.apply_role_name}-permissions"
  description = "Permissions for Terraform dev network applies."
  policy      = data.aws_iam_policy_document.terraform_apply_permissions.json

  tags = merge(local.common_tags, {
    Name = "${local.apply_role_name}-permissions"
  })
}

resource "aws_iam_role_policy_attachment" "terraform_apply" {
  role       = aws_iam_role.terraform_apply.name
  policy_arn = aws_iam_policy.terraform_apply.arn
}
