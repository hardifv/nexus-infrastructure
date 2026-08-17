output "bucket_id" {
  description = "The ID of the S3 bucket used for Terraform state."
  value       = module.backend.bucket_id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket used for Terraform state."
  value       = module.backend.bucket_arn
}

output "bucket_region" {
  description = "The AWS region of the S3 bucket used for Terraform state."
  value       = module.backend.bucket_region
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider."
  value       = module.github_oidc.oidc_provider_arn
}

output "terraform_plan_role_arn" {
  description = "ARN of the IAM role used for Terraform pull-request plans."
  value       = module.github_oidc.terraform_plan_role_arn
}

output "terraform_apply_role_arn" {
  description = "ARN of the IAM role used for Terraform dev applies."
  value       = module.github_oidc.terraform_apply_role_arn
}

output "terraform_plan_policy_arn" {
  description = "ARN of the customer-managed policy for Terraform plans."
  value       = module.github_oidc.terraform_plan_policy_arn
}

output "terraform_apply_policy_arn" {
  description = "ARN of the customer-managed policy for Terraform applies."
  value       = module.github_oidc.terraform_apply_policy_arn
}
