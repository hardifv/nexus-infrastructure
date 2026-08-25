output "volume_id" {
  description = "ID of the persistent Nexus EBS volume."
  value       = aws_ebs_volume.this.id
}

output "volume_arn" {
  description = "ARN of the persistent Nexus EBS volume."
  value       = aws_ebs_volume.this.arn
}

output "availability_zone" {
  description = "Availability Zone of the persistent Nexus EBS volume."
  value       = aws_ebs_volume.this.availability_zone
}
