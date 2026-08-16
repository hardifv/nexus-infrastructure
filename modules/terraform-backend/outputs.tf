output "bucket_id" {
  description = "Name of the Terraform state S3 bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the Terraform state S3 bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_region" {
  description = "AWS region containing the Terraform state S3 bucket."
  value       = aws_s3_bucket.this.region
}
