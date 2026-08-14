output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR assigned to the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Map of Availability Zone to public subnet ID."
  value       = { for az, subnet in aws_subnet.public : az => subnet.id }
}

output "private_subnet_ids" {
  description = "Map of Availability Zone to private subnet ID."
  value       = { for az, subnet in aws_subnet.private : az => subnet.id }
}

output "nat_gateway_id" {
  description = "ID of the shared dev NAT Gateway."
  value       = aws_nat_gateway.this.id
}

output "nat_availability_zone" {
  description = "Availability Zone containing the shared NAT Gateway."
  value       = local.nat_availability_zone
}

