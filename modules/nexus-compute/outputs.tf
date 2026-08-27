output "instance_id" {
  description = "ID of the initial Nexus EC2 instance."
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "ARN of the initial Nexus EC2 instance."
  value       = aws_instance.this.arn
}

output "private_ip" {
  description = "Private IP address of the initial Nexus EC2 instance."
  value       = aws_instance.this.private_ip
}

output "availability_zone" {
  description = "Availability Zone of the initial Nexus EC2 instance."
  value       = aws_instance.this.availability_zone
}

output "launch_template_id" {
  description = "ID of the Nexus Launch Template."
  value       = aws_launch_template.this.id
}

output "launch_template_arn" {
  description = "ARN of the Nexus Launch Template."
  value       = aws_launch_template.this.arn
}

output "launch_template_latest_version" {
  description = "Concrete latest version number of the Nexus Launch Template consumed by the EC2 instance."
  value       = aws_launch_template.this.latest_version
}
