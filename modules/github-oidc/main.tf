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

  rds_db_instance_arn_pattern    = "arn:*:rds:${var.aws_region}:*:db:${var.managed_project_name}-${var.environment_name}-postgresql"
  rds_subnet_group_arn_pattern   = "arn:*:rds:${var.aws_region}:*:subgrp:${var.managed_project_name}-${var.environment_name}-rds-subnets"
  rds_kms_key_arn_pattern        = "arn:*:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/*"
  rds_managed_secret_arn_pattern = "arn:*:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:rds!db-*"
  ebs_volume_arn_pattern         = "arn:*:ec2:${var.aws_region}:*:volume/*"

  nexus_runtime_name                  = "${var.managed_project_name}-${var.environment_name}-nexus-ec2"
  nexus_secret_policy_name            = "${var.managed_project_name}-${var.environment_name}-nexus-secret-access"
  nexus_launch_template_name          = "${var.managed_project_name}-${var.environment_name}-nexus"
  nexus_runtime_role_arn_pattern      = "arn:*:iam::*:role/${local.nexus_runtime_name}"
  nexus_instance_profile_arn_pattern  = "arn:*:iam::*:instance-profile/${local.nexus_runtime_name}"
  nexus_secret_policy_arn_pattern     = "arn:*:iam::*:policy/${local.nexus_secret_policy_name}"
  nexus_launch_template_arn_pattern   = "arn:*:ec2:${var.aws_region}:*:launch-template/*"
  nexus_instance_arn_pattern          = "arn:*:ec2:${var.aws_region}:*:instance/*"
  nexus_network_interface_arn_pattern = "arn:*:ec2:${var.aws_region}:*:network-interface/*"
  nexus_root_volume_arn_pattern       = "arn:*:ec2:${var.aws_region}:*:volume/*"
  nexus_private_subnet_arn_pattern    = "arn:*:ec2:${var.aws_region}:*:subnet/*"
  nexus_security_group_arn_pattern    = "arn:*:ec2:${var.aws_region}:*:security-group/*"
  nexus_approved_ami_arn              = "arn:*:ec2:${var.aws_region}::image/ami-0c02fb55956c7d316"

  common_tags = merge(var.tags, {
    Project   = var.project_name
    ManagedBy = "Terraform"
  })
}

data "aws_caller_identity" "current" {}

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

  statement {
    sid    = "DescribeRDSResources"
    effect = "Allow"
    actions = [
      "rds:DescribeDBInstances",
      "rds:DescribeDBSubnetGroups",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid     = "ReadRDSResourceTags"
    effect  = "Allow"
    actions = ["rds:ListTagsForResource"]
    resources = [
      local.rds_db_instance_arn_pattern,
      local.rds_subnet_group_arn_pattern,
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid    = "ReadNexusRuntimeRole"
    effect = "Allow"
    actions = [
      "iam:GetRolePolicy",
      "iam:GetRole",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:ListRolePolicies",
    ]
    resources = [local.nexus_runtime_role_arn_pattern]
  }

  statement {
    sid       = "ReadNexusInstanceProfile"
    effect    = "Allow"
    actions   = ["iam:GetInstanceProfile"]
    resources = [local.nexus_instance_profile_arn_pattern]
  }

  statement {
    sid    = "ReadNexusSecretPolicy"
    effect = "Allow"
    actions = [
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
    ]
    resources = [local.nexus_secret_policy_arn_pattern]
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
    sid    = "DescribeRDSResources"
    effect = "Allow"
    actions = [
      "rds:DescribeDBInstances",
      "rds:DescribeDBSubnetGroups",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid     = "ReadRDSResourceTags"
    effect  = "Allow"
    actions = ["rds:ListTagsForResource"]
    resources = [
      local.rds_db_instance_arn_pattern,
      local.rds_subnet_group_arn_pattern,
    ]

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
    sid    = "ManageRDSDBInstance"
    effect = "Allow"
    actions = [
      "rds:CreateDBInstance",
      "rds:DeleteDBInstance",
      "rds:ModifyDBInstance",
    ]
    resources = [
      local.rds_db_instance_arn_pattern,
      local.rds_subnet_group_arn_pattern,
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid    = "ManageRDSDBSubnetGroup"
    effect = "Allow"
    actions = [
      "rds:CreateDBSubnetGroup",
      "rds:DeleteDBSubnetGroup",
      "rds:ModifyDBSubnetGroup",
    ]
    resources = [local.rds_subnet_group_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid    = "ManageRDSResourceTags"
    effect = "Allow"
    actions = [
      "rds:AddTagsToResource",
      "rds:RemoveTagsFromResource",
    ]
    resources = [
      local.rds_db_instance_arn_pattern,
      local.rds_subnet_group_arn_pattern,
    ]

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
      "ec2:DisassociateAddress",
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

data "aws_iam_policy_document" "terraform_apply_ebs_permissions" {
  statement {
    sid       = "CreateTaggedEBSVolume"
    effect    = "Allow"
    actions   = ["ec2:CreateVolume"]
    resources = [local.ebs_volume_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Project"
      values   = [var.managed_project_name]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = [var.environment_name]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/ManagedBy"
      values   = ["Terraform"]
    }
  }

  statement {
    sid    = "ManageTaggedEBSVolume"
    effect = "Allow"
    actions = [
      "ec2:DeleteVolume",
      "ec2:ModifyVolume",
    ]
    resources = [local.ebs_volume_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Project"
      values   = [var.managed_project_name]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Environment"
      values   = [var.environment_name]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/ManagedBy"
      values   = ["Terraform"]
    }
  }
}

data "aws_iam_policy_document" "terraform_apply_rds_encryption_support_permissions" {
  statement {
    sid       = "DescribeRDSManagedKMSKeys"
    effect    = "Allow"
    actions   = ["kms:DescribeKey"]
    resources = [local.rds_kms_key_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid       = "CreateRDSManagedKMSGrant"
    effect    = "Allow"
    actions   = ["kms:CreateGrant"]
    resources = [local.rds_kms_key_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["rds.${var.aws_region}.amazonaws.com"]
    }

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }

  statement {
    sid    = "CreateTaggedRDSManagedSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:CreateSecret",
      "secretsmanager:TagResource",
    ]
    resources = [local.rds_managed_secret_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }
}

data "aws_iam_policy_document" "terraform_apply_runtime_iam_permissions" {
  statement {
    sid       = "CreateTaggedNexusRuntimeRole"
    effect    = "Allow"
    actions   = ["iam:CreateRole"]
    resources = [local.nexus_runtime_role_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Project"
      values   = [var.managed_project_name]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = [var.environment_name]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/ManagedBy"
      values   = ["Terraform"]
    }
  }

  statement {
    sid    = "ReadNexusRuntimeRole"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:ListRolePolicies",
    ]
    resources = [local.nexus_runtime_role_arn_pattern]
  }

  statement {
    sid    = "ManageTaggedNexusRuntimeRole"
    effect = "Allow"
    actions = [
      "iam:DeleteRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRole",
    ]
    resources = [local.nexus_runtime_role_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "iam:ResourceTag/Project"
      values   = [var.managed_project_name]
    }

    condition {
      test     = "StringEquals"
      variable = "iam:ResourceTag/Environment"
      values   = [var.environment_name]
    }

    condition {
      test     = "StringEquals"
      variable = "iam:ResourceTag/ManagedBy"
      values   = ["Terraform"]
    }
  }

  statement {
    sid       = "CreateTaggedNexusInstanceProfile"
    effect    = "Allow"
    actions   = ["iam:CreateInstanceProfile"]
    resources = [local.nexus_instance_profile_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Project"
      values   = [var.managed_project_name]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = [var.environment_name]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/ManagedBy"
      values   = ["Terraform"]
    }
  }

  statement {
    sid       = "ReadNexusInstanceProfile"
    effect    = "Allow"
    actions   = ["iam:GetInstanceProfile"]
    resources = [local.nexus_instance_profile_arn_pattern]
  }

  statement {
    sid    = "ManageTaggedNexusInstanceProfile"
    effect = "Allow"
    actions = [
      "iam:AddRoleToInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:UntagInstanceProfile",
    ]
    resources = [local.nexus_instance_profile_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "iam:ResourceTag/Project"
      values   = [var.managed_project_name]
    }

    condition {
      test     = "StringEquals"
      variable = "iam:ResourceTag/Environment"
      values   = [var.environment_name]
    }

    condition {
      test     = "StringEquals"
      variable = "iam:ResourceTag/ManagedBy"
      values   = ["Terraform"]
    }
  }

  statement {
    sid       = "CreateTaggedNexusSecretPolicy"
    effect    = "Allow"
    actions   = ["iam:CreatePolicy"]
    resources = [local.nexus_secret_policy_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Project"
      values   = [var.managed_project_name]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = [var.environment_name]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/ManagedBy"
      values   = ["Terraform"]
    }
  }

  statement {
    sid    = "ReadNexusSecretPolicy"
    effect = "Allow"
    actions = [
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListEntitiesForPolicy",
      "iam:ListPolicyVersions",
    ]
    resources = [local.nexus_secret_policy_arn_pattern]
  }

  statement {
    sid    = "ManageTaggedNexusSecretPolicy"
    effect = "Allow"
    actions = [
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:TagPolicy",
      "iam:UntagPolicy",
    ]
    resources = [local.nexus_secret_policy_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "iam:ResourceTag/Project"
      values   = [var.managed_project_name]
    }

    condition {
      test     = "StringEquals"
      variable = "iam:ResourceTag/Environment"
      values   = [var.environment_name]
    }

    condition {
      test     = "StringEquals"
      variable = "iam:ResourceTag/ManagedBy"
      values   = ["Terraform"]
    }
  }

  statement {
    sid    = "ManageApprovedNexusRoleAttachments"
    effect = "Allow"
    actions = [
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
    ]
    resources = [local.nexus_runtime_role_arn_pattern]

    condition {
      test     = "ArnLike"
      variable = "iam:PolicyARN"
      values = [
        "arn:*:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "arn:*:iam::aws:policy/CloudWatchAgentServerPolicy",
        local.nexus_secret_policy_arn_pattern,
      ]
    }
  }

  statement {
    sid       = "PassNexusRuntimeRoleToEC2"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [local.nexus_runtime_role_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "terraform_apply_nexus_compute_permissions" {
  statement {
    sid       = "CreateTaggedNexusLaunchTemplate"
    effect    = "Allow"
    actions   = ["ec2:CreateLaunchTemplate"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Project"
      values   = [var.managed_project_name]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = [var.environment_name]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/ManagedBy"
      values   = ["Terraform"]
    }
  }

  statement {
    sid    = "ManageTaggedNexusLaunchTemplate"
    effect = "Allow"
    actions = [
      "ec2:CreateLaunchTemplateVersion",
      "ec2:DeleteLaunchTemplate",
      "ec2:DeleteLaunchTemplateVersions",
    ]
    resources = [local.nexus_launch_template_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Project"
      values   = [var.managed_project_name]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Environment"
      values   = [var.environment_name]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/ManagedBy"
      values   = ["Terraform"]
    }
  }

  statement {
    sid       = "ModifyNexusLaunchTemplate"
    effect    = "Allow"
    actions   = ["ec2:ModifyLaunchTemplate"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid       = "RunApprovedNexusAMI"
    effect    = "Allow"
    actions   = ["ec2:RunInstances"]
    resources = [local.nexus_approved_ami_arn]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid     = "RunInTaggedNexusNetwork"
    effect  = "Allow"
    actions = ["ec2:RunInstances"]
    resources = [
      local.nexus_launch_template_arn_pattern,
      local.nexus_private_subnet_arn_pattern,
      local.nexus_security_group_arn_pattern,
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Project"
      values   = [var.managed_project_name]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Environment"
      values   = [var.environment_name]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/ManagedBy"
      values   = ["Terraform"]
    }
  }

  statement {
    sid     = "RunTaggedNexusInstanceAndRootVolume"
    effect  = "Allow"
    actions = ["ec2:RunInstances"]
    resources = [
      local.nexus_instance_arn_pattern,
      local.nexus_root_volume_arn_pattern,
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Project"
      values   = [var.managed_project_name]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = [var.environment_name]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/ManagedBy"
      values   = ["Terraform"]
    }
  }

  statement {
    sid       = "CreatePrivateNexusNetworkInterface"
    effect    = "Allow"
    actions   = ["ec2:RunInstances"]
    resources = [local.nexus_network_interface_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }

    condition {
      test     = "Bool"
      variable = "ec2:AssociatePublicIpAddress"
      values   = ["false"]
    }
  }

  statement {
    sid    = "ManageTaggedNexusInstance"
    effect = "Allow"
    actions = [
      "ec2:ModifyInstanceAttribute",
      "ec2:TerminateInstances",
    ]
    resources = [local.nexus_instance_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Project"
      values   = [var.managed_project_name]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Environment"
      values   = [var.environment_name]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/ManagedBy"
      values   = ["Terraform"]
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

resource "aws_iam_policy" "terraform_apply_ebs" {
  name        = "${local.apply_role_name}-ebs-permissions"
  description = "Permissions for Terraform dev EBS volume management."
  policy      = data.aws_iam_policy_document.terraform_apply_ebs_permissions.json

  tags = merge(local.common_tags, {
    Name = "${local.apply_role_name}-ebs-permissions"
  })
}

resource "aws_iam_role_policy_attachment" "terraform_apply_ebs" {
  role       = aws_iam_role.terraform_apply.name
  policy_arn = aws_iam_policy.terraform_apply_ebs.arn
}

resource "aws_iam_policy" "terraform_apply_runtime_iam" {
  name        = "${local.apply_role_name}-runtime-iam-permissions"
  description = "Permissions for Terraform Nexus runtime IAM management."
  policy      = data.aws_iam_policy_document.terraform_apply_runtime_iam_permissions.json

  tags = merge(local.common_tags, {
    Name = "${local.apply_role_name}-runtime-iam-permissions"
  })
}

resource "aws_iam_role_policy_attachment" "terraform_apply_runtime_iam" {
  role       = aws_iam_role.terraform_apply.name
  policy_arn = aws_iam_policy.terraform_apply_runtime_iam.arn
}

resource "aws_iam_policy" "terraform_apply_nexus_compute" {
  name        = "${local.apply_role_name}-nexus-compute-permissions"
  description = "Permissions for Terraform Nexus EC2 compute management."
  policy      = data.aws_iam_policy_document.terraform_apply_nexus_compute_permissions.json

  tags = merge(local.common_tags, {
    Name = "${local.apply_role_name}-nexus-compute-permissions"
  })
}

resource "aws_iam_role_policy_attachment" "terraform_apply_nexus_compute" {
  role       = aws_iam_role.terraform_apply.name
  policy_arn = aws_iam_policy.terraform_apply_nexus_compute.arn
}

resource "aws_iam_policy" "terraform_apply_rds_encryption_support" {
  name        = "${local.apply_role_name}-rds-encryption-support-permissions"
  description = "Permissions supporting encrypted RDS creation and its managed master secret."
  policy      = data.aws_iam_policy_document.terraform_apply_rds_encryption_support_permissions.json

  tags = merge(local.common_tags, {
    Name = "${local.apply_role_name}-rds-encryption-support-permissions"
  })
}

resource "aws_iam_role_policy_attachment" "terraform_apply_rds_encryption_support" {
  role       = aws_iam_role.terraform_apply.name
  policy_arn = aws_iam_policy.terraform_apply_rds_encryption_support.arn
}
