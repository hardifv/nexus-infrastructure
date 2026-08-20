variable "aws_region" {
  description = "AWS region used by the dev environment."
  type        = string
}

variable "project_name" {
  description = "Project name used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR assigned to the dev VPC."
  type        = string
}

variable "public_subnets" {
  description = "Map of Availability Zone to public subnet CIDR."
  type        = map(string)
}

variable "private_subnets" {
  description = "Map of Availability Zone to private subnet CIDR."
  type        = map(string)
}

variable "allowed_client_cidrs" {
  description = "IPv4 CIDR blocks allowed to access the ALB on HTTP and HTTPS."
  type        = set(string)
}