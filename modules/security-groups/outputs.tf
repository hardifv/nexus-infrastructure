output "alb_security_group_id" {
  description = "ID of the Application Load Balancer Security Group."
  value       = aws_security_group.alb.id
}

output "nexus_security_group_id" {
  description = "ID of the Nexus EC2 Security Group."
  value       = aws_security_group.nexus.id
}

output "rds_security_group_id" {
  description = "ID of the RDS PostgreSQL Security Group."
  value       = aws_security_group.rds.id
}
