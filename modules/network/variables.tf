variable "project_name" {
  description = "Project name used in resource names and tags."
  type        = string

  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "project_name cannot be empty."
  }
}

variable "environment" {
  description = "Deployment environment, for example dev, staging, or production."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be dev, staging, or production."
  }
}

variable "vpc_cidr" {
  description = "IPv4 CIDR assigned to the VPC."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR."
  }
}

variable "public_subnets" {
  description = "Map of Availability Zone to public subnet CIDR."
  type        = map(string)

  validation {
    condition = (
      length(var.public_subnets) >= 2 &&
      alltrue([for cidr in values(var.public_subnets) : can(cidrnetmask(cidr))])
    )
    error_message = "public_subnets must contain at least two AZs with valid IPv4 CIDRs."
  }
}

variable "private_subnets" {
  description = "Map of Availability Zone to private subnet CIDR."
  type        = map(string)

  validation {
    condition = (
      length(var.private_subnets) >= 2 &&
      alltrue([for cidr in values(var.private_subnets) : can(cidrnetmask(cidr))])
    )
    error_message = "private_subnets must contain at least two AZs with valid IPv4 CIDRs."
  }

  validation {
    condition     = toset(keys(var.private_subnets)) == toset(keys(var.public_subnets))
    error_message = "Public and private subnet maps must use the same Availability Zones."
  }
}

variable "tags" {
  description = "Additional tags applied to every resource."
  type        = map(string)
  default     = {}
}
