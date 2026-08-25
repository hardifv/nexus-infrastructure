# TECH LEAD TASK:
# Expose these module outputs from the dev root module:
# - vpc_id
# - public_subnet_ids
# - private_subnet_ids
# - nat_gateway_id

output "vpc_id" {
  description = "ID of the dev VPC."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Map of Availability Zone to public subnet ID."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Map of Availability Zone to private subnet ID."
  value       = module.network.private_subnet_ids
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway."
  value       = module.network.nat_gateway_id
}

output "alb_security_group_id" {
  description = "ID of the Application Load Balancer Security Group."
  value       = module.security_groups.alb_security_group_id
}

output "nexus_security_group_id" {
  description = "ID of the Nexus EC2 Security Group."
  value       = module.security_groups.nexus_security_group_id
}

output "rds_security_group_id" {
  description = "ID of the RDS PostgreSQL Security Group."
  value       = module.security_groups.rds_security_group_id
}

output "load_balancer_arn" {
  description = "ARN of the Application Load Balancer."
  value       = module.load_balancer.load_balancer_arn
}

output "load_balancer_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = module.load_balancer.load_balancer_dns_name
}

output "load_balancer_zone_id" {
  description = "Canonical hosted zone ID of the Application Load Balancer."
  value       = module.load_balancer.load_balancer_zone_id
}

output "target_group_arn" {
  description = "ARN of the Nexus Target Group."
  value       = module.load_balancer.target_group_arn
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener."
  value       = module.load_balancer.http_listener_arn
}

output "rds_db_instance_id" {
  description = "Identifier of the dev RDS PostgreSQL instance."
  value       = module.rds_postgresql.db_instance_id
}

output "rds_endpoint" {
  description = "Connection endpoint including the port of the dev RDS PostgreSQL instance."
  value       = module.rds_postgresql.endpoint
}

output "rds_port" {
  description = "Port of the dev RDS PostgreSQL instance."
  value       = module.rds_postgresql.port
}

output "rds_database_name" {
  description = "Name of the initial dev PostgreSQL database."
  value       = module.rds_postgresql.database_name
}

output "rds_master_user_secret_arn" {
  description = "ARN of the RDS-managed Secrets Manager secret containing the dev master credentials."
  value       = module.rds_postgresql.master_user_secret_arn
  sensitive   = true
}

output "nexus_data_volume_id" {
  description = "ID of the persistent Nexus EBS volume."
  value       = module.ebs_volume.volume_id
}

output "nexus_data_volume_arn" {
  description = "ARN of the persistent Nexus EBS volume."
  value       = module.ebs_volume.volume_arn
}

output "nexus_data_volume_availability_zone" {
  description = "Availability Zone of the persistent Nexus EBS volume."
  value       = module.ebs_volume.availability_zone
}