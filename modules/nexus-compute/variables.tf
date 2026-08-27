variable "project_name" {
  description = "Project name used in deterministic Nexus compute resource names and tags."
  type        = string

  validation {
    condition     = length(var.project_name) <= 30 && can(regex("^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$", var.project_name))
    error_message = "project_name must be 1-30 lowercase characters, start with a letter, and contain only letters, numbers, or single hyphens."
  }
}

variable "environment" {
  description = "Environment name used in deterministic Nexus compute resource names and tags."
  type        = string

  validation {
    condition     = length(var.environment) <= 15 && can(regex("^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$", var.environment))
    error_message = "environment must be 1-15 lowercase characters, start with a letter, and contain only letters, numbers, or single hyphens."
  }
}

variable "ami_id" {
  description = "AMI ID used by the Nexus Launch Template."
  type        = string

  validation {
    condition     = can(regex("^ami-[0-9a-f]{8,17}$", var.ami_id))
    error_message = "ami_id must be a valid AWS AMI ID."
  }
}

variable "subnet_id" {
  description = "Private subnet ID in which the initial Nexus EC2 instance is created."
  type        = string

  validation {
    condition     = can(regex("^subnet-[0-9a-f]{8,17}$", var.subnet_id))
    error_message = "subnet_id must be a valid AWS subnet ID."
  }
}

variable "security_group_ids" {
  description = "Security Group IDs assigned to the Nexus network interface."
  type        = set(string)

  validation {
    condition = (
      length(var.security_group_ids) >= 1 &&
      alltrue([for security_group_id in var.security_group_ids : can(regex("^sg-[0-9a-f]{8,17}$", security_group_id))])
    )
    error_message = "security_group_ids must contain at least one valid AWS Security Group ID."
  }
}

variable "instance_profile_name" {
  description = "Name of the IAM instance profile assigned to the Nexus Launch Template."
  type        = string

  validation {
    condition     = length(trimspace(var.instance_profile_name)) >= 1 && length(var.instance_profile_name) <= 128 && can(regex("^[A-Za-z0-9+=,.@_-]+$", var.instance_profile_name))
    error_message = "instance_profile_name must be a valid non-empty IAM instance profile name of at most 128 characters."
  }
}

variable "instance_type" {
  description = "EC2 instance type used by the Nexus Launch Template."
  type        = string
  default     = "t3.medium"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*\\.[a-z0-9-]+$", var.instance_type))
    error_message = "instance_type must be a plausible EC2 instance type such as t3.medium."
  }
}

variable "root_volume_size" {
  description = "Size of the encrypted EC2 root volume in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size == floor(var.root_volume_size) && var.root_volume_size > 0
    error_message = "root_volume_size must be a positive integer in GiB."
  }
}

variable "root_volume_type" {
  description = "EBS type used for the EC2 root volume; this module supports gp3 only."
  type        = string
  default     = "gp3"

  validation {
    condition     = var.root_volume_type == "gp3"
    error_message = "root_volume_type must be gp3."
  }
}

variable "root_device_name" {
  description = "Device name used for the EC2 root volume mapping."
  type        = string
  default     = "/dev/xvda"

  validation {
    condition     = length(trimspace(var.root_device_name)) > 0
    error_message = "root_device_name must not be empty."
  }
}

variable "detailed_monitoring_enabled" {
  description = "Whether detailed EC2 monitoring is enabled."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags applied to Nexus compute resources; standard module tags take precedence."
  type        = map(string)
  default     = {}
}
