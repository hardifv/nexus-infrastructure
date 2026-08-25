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

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  vpc_id               = module.network.vpc_id
  allowed_client_cidrs = var.allowed_client_cidrs


  tags = {
    Owner      = "OperationOffer"
    CostCenter = "Learning"
  }
}

module "load_balancer" {
  source = "../../modules/load-balancer"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = toset(values(module.network.public_subnet_ids))
  alb_security_group_id = module.security_groups.alb_security_group_id

  tags = {
    Owner      = "OperationOffer"
    CostCenter = "Learning"
  }
}

module "rds_postgresql" {
  source = "../../modules/rds-postgresql"

  project_name          = var.project_name
  environment           = var.environment
  private_subnet_ids    = toset(values(module.network.private_subnet_ids))
  rds_security_group_id = module.security_groups.rds_security_group_id

  tags = {
    Owner      = "OperationOffer"
    CostCenter = "Learning"
  }
}

module "ebs_volume" {
  source = "../../modules/ebs-persistent-storage"

  project_name      = var.project_name
  environment       = var.environment
  availability_zone = sort(keys(module.network.private_subnet_ids))[0]

  tags = {
    Owner      = "OperationOffer"
    CostCenter = "Learning"
  }
}