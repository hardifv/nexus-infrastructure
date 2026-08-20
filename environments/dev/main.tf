# TECH LEAD TASK:
# Consume ../../modules/network here.
#
# Use the variables already declared in variables.tf and add these tags:
# Owner      = "OperationOffer"
# CostCenter = "Learning"

module "network" {
  source = "../../modules/network"

  project_name    = var.project_name
  environment     = var.environment
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  tags = {
    Owner      = "OperationOffer"
    CostCenter = "Learning"
  }
}

module "security_groups" {
  source = "../../modules/security-groups"

  vpc_id               = module.network.vpc_id
  vpc_cidr             = var.vpc_cidr
  project_name         = var.project_name
  environment          = var.environment
  allowed_client_cidrs = var.allowed_client_cidrs



  tags = {
    Owner      = "OperationOffer"
    CostCenter = "Learning"
  }
}