variable "vpc_id" {
  description = "ID of the VPC where the security groups are created."
  type        = string

  validation {
    condition     = can(regex("^vpc-[0-9a-f]{8,17}$", var.vpc_id))
    error_message = "vpc_id must be a valid AWS VPC ID."
  }
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block of the VPC, used to scope DNS egress."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "project_name" {
  description = "Project name used in resource names and tags."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-]*$", var.project_name))
    error_message = "project_name must start with a letter or number and contain only letters, numbers, or hyphens."
  }
}

variable "environment" {
  description = "Environment name used in resource names and tags."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-]*$", var.environment))
    error_message = "environment must start with a letter or number and contain only letters, numbers, or hyphens."
  }
}

variable "allowed_client_cidrs" {
  description = "IPv4 CIDR blocks allowed to access the ALB on HTTP and HTTPS."
  type        = set(string)

  validation {
    condition     = length(var.allowed_client_cidrs) > 0 && alltrue([for cidr in var.allowed_client_cidrs : can(cidrnetmask(cidr))])
    error_message = "allowed_client_cidrs must contain at least one valid IPv4 CIDR block."
  }
}

variable "nexus_port" {
  description = "TCP port on which Nexus receives application traffic."
  type        = number
  default     = 8081

  validation {
    condition     = var.nexus_port == floor(var.nexus_port) && var.nexus_port >= 1 && var.nexus_port <= 65535
    error_message = "nexus_port must be an integer between 1 and 65535."
  }
}

variable "database_port" {
  description = "TCP port on which PostgreSQL receives database traffic."
  type        = number
  default     = 5432

  validation {
    condition     = var.database_port == floor(var.database_port) && var.database_port >= 1 && var.database_port <= 65535
    error_message = "database_port must be an integer between 1 and 65535."
  }
}

variable "tags" {
  description = "Additional tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
