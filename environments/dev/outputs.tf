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