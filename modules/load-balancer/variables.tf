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

variable "vpc_id" {
  description = "ID of the VPC where the Nexus Target Group is created."
  type        = string

  validation {
    condition     = can(regex("^vpc-[0-9a-f]{8,17}$", var.vpc_id))
    error_message = "vpc_id must be a valid AWS VPC ID."
  }
}

variable "public_subnet_ids" {
  description = "Public subnet IDs used by the internet-facing Application Load Balancer."
  type        = set(string)

  validation {
    condition = (
      length(var.public_subnet_ids) >= 2 &&
      alltrue([for subnet_id in var.public_subnet_ids : can(regex("^subnet-[0-9a-f]{8,17}$", subnet_id))])
    )
    error_message = "public_subnet_ids must contain at least two valid AWS subnet IDs."
  }
}

variable "alb_security_group_id" {
  description = "ID of the Security Group attached to the Application Load Balancer."
  type        = string

  validation {
    condition     = can(regex("^sg-[0-9a-f]{8,17}$", var.alb_security_group_id))
    error_message = "alb_security_group_id must be a valid AWS Security Group ID."
  }
}

variable "nexus_port" {
  description = "Port on which Nexus receives traffic from the Target Group."
  type        = number
  default     = 8081

  validation {
    condition     = var.nexus_port == floor(var.nexus_port) && var.nexus_port >= 1 && var.nexus_port <= 65535
    error_message = "nexus_port must be an integer between 1 and 65535."
  }
}

variable "health_check_path" {
  description = "HTTP path used by the Target Group to check Nexus health."
  type        = string
  default     = "/service/rest/v1/status"

  validation {
    condition     = startswith(var.health_check_path, "/") && length(var.health_check_path) <= 1024
    error_message = "health_check_path must start with / and contain no more than 1024 characters."
  }
}

variable "deletion_protection_enabled" {
  description = "Whether deletion protection is enabled for the Application Load Balancer."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
