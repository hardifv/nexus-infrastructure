output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider."
  value       = data.aws_iam_openid_connect_provider.github.arn
}

output "terraform_plan_role_arn" {
  description = "ARN of the IAM role trusted by GitHub pull-request workflows."
  value       = aws_iam_role.terraform_plan.arn
}

output "terraform_apply_role_arn" {
  description = "ARN of the IAM role trusted by the configured GitHub Environment."
  value       = aws_iam_role.terraform_apply.arn
}

output "terraform_plan_policy_arn" {
  description = "ARN of the customer-managed policy attached to the Terraform plan role."
  value       = aws_iam_policy.terraform_plan.arn
}

output "terraform_apply_policy_arn" {
  description = "ARN of the customer-managed policy attached to the Terraform apply role."
  value       = aws_iam_policy.terraform_apply.arn
}
