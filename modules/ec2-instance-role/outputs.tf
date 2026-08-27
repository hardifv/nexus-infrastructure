output "role_name" {
  description = "Name of the Nexus EC2 runtime IAM role."
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "ARN of the Nexus EC2 runtime IAM role."
  value       = aws_iam_role.this.arn
}

output "instance_profile_name" {
  description = "Name of the Nexus EC2 IAM instance profile."
  value       = aws_iam_instance_profile.this.name
}

output "instance_profile_arn" {
  description = "ARN of the Nexus EC2 IAM instance profile."
  value       = aws_iam_instance_profile.this.arn
}

output "secret_policy_arn" {
  description = "ARN of the customer-managed policy granting read-only access to the RDS-managed secret."
  value       = aws_iam_policy.secret_access.arn
}
