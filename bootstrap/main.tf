module "backend" {
  source = "../modules/terraform-backend"

  bucket_name  = var.bucket_name
  project_name = var.project_name
  environment  = var.environment

  tags = {
    Owner      = "OperationOffer"
    CostCenter = "Learning"
  }
}

module "github_oidc" {
  source = "../modules/github-oidc"

  github_repository    = var.github_repository
  github_owner_id      = var.github_owner_id
  github_repository_id = var.github_repository_id
  project_name         = var.project_name
  environment_name     = "dev"
  state_bucket_arn     = module.backend.bucket_arn
  state_key            = "nexus/dev/terraform.tfstate"
  aws_region           = var.aws_region

  tags = {
    Owner      = "OperationOffer"
    CostCenter = "Learning"
  }
}
