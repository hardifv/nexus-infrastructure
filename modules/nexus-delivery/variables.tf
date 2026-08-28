variable "project_name" {
  description = "Project name used in deterministic Nexus delivery resource names and tags."
  type        = string

  validation {
    condition     = length(var.project_name) <= 30 && can(regex("^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$", var.project_name))
    error_message = "project_name must be 1-30 lowercase characters, start with a letter, and contain only letters, numbers, or single hyphens."
  }
}

variable "environment" {
  description = "Environment name used in deterministic Nexus delivery resource names and tags."
  type        = string

  validation {
    condition     = length(var.environment) <= 15 && can(regex("^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$", var.environment))
    error_message = "environment must be 1-15 lowercase characters, start with a letter, and contain only letters, numbers, or single hyphens."
  }
}

variable "instance_id" {
  description = "ID of the existing Nexus EC2 instance."
  type        = string

  validation {
    condition     = can(regex("^i-[0-9a-f]{8,17}$", var.instance_id))
    error_message = "instance_id must be a valid EC2 instance ID."
  }
}

variable "volume_id" {
  description = "ID of the existing persistent Nexus EBS volume."
  type        = string

  validation {
    condition     = can(regex("^vol-[0-9a-f]{8,17}$", var.volume_id))
    error_message = "volume_id must be a valid EBS volume ID."
  }
}

variable "target_group_arn" {
  description = "ARN of the existing Nexus Application Load Balancer Target Group."
  type        = string

  validation {
    condition     = can(regex("^arn:(aws|aws-us-gov|aws-cn):elasticloadbalancing:[a-z0-9-]+:[0-9]{12}:targetgroup/[A-Za-z0-9-]+/[0-9a-f]+$", var.target_group_arn))
    error_message = "target_group_arn must be a valid Application Load Balancer Target Group ARN."
  }
}

variable "device_name" {
  description = "Requested Linux device name used by the EC2 EBS attachment API."
  type        = string
  default     = "/dev/sdf"

  validation {
    condition     = can(regex("^/dev/sd[f-p]$", var.device_name))
    error_message = "device_name must be an allowed secondary EBS device name from /dev/sdf through /dev/sdp."
  }
}

variable "nexus_port" {
  description = "Port on which Nexus listens and is registered with the Target Group."
  type        = number
  default     = 8081

  validation {
    condition     = var.nexus_port == floor(var.nexus_port) && var.nexus_port >= 1 && var.nexus_port <= 65535
    error_message = "nexus_port must be an integer between 1 and 65535."
  }
}

variable "tags" {
  description = "Additional tags applied to taggable Nexus delivery resources."
  type        = map(string)
  default     = {}
}
