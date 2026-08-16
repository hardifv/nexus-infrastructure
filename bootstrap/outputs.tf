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