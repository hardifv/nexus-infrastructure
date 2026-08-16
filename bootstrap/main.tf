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