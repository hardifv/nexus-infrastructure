variable "project_name" {
  description = "Project name used in deterministic EBS volume names and tags."
  type        = string

  validation {
    condition     = length(var.project_name) <= 30 && can(regex("^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$", var.project_name))
    error_message = "project_name must be 1-30 lowercase characters, start with a letter, and contain only letters, numbers, or single hyphens."
  }
}

variable "environment" {
  description = "Environment name used in deterministic EBS volume names and tags."
  type        = string

  validation {
    condition     = length(var.environment) <= 15 && can(regex("^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$", var.environment))
    error_message = "environment must be 1-15 lowercase characters, start with a letter, and contain only letters, numbers, or single hyphens."
  }
}

variable "availability_zone" {
  description = "AWS Availability Zone in which the persistent EBS volume is created."
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}(?:-[a-z0-9]+)+-[0-9][a-z]$", var.availability_zone))
    error_message = "availability_zone must be a plausible AWS Availability Zone such as us-east-1a."
  }
}

variable "size" {
  description = "Size of the gp3 EBS volume in GiB."
  type        = number
  default     = 50

  validation {
    condition     = var.size == floor(var.size) && var.size >= 1 && var.size <= 65536
    error_message = "size must be an integer between 1 and 65536 GiB."
  }
}

variable "iops" {
  description = "Provisioned IOPS for the gp3 EBS volume."
  type        = number
  default     = 3000

  validation {
    condition = (
      var.iops == floor(var.iops) &&
      var.iops >= 3000 &&
      var.iops <= 80000 &&
      var.iops <= max(3000, var.size * 500)
    )
    error_message = "iops must be an integer between 3000 and 80000 and must not exceed 500 IOPS per GiB above the 3000 IOPS baseline."
  }
}

variable "throughput" {
  description = "Provisioned throughput for the gp3 EBS volume in MiB/s."
  type        = number
  default     = 125

  validation {
    condition = (
      var.throughput == floor(var.throughput) &&
      var.throughput >= 125 &&
      var.throughput <= 2000 &&
      var.throughput <= var.iops * 0.25
    )
    error_message = "throughput must be an integer between 125 and 2000 MiB/s and must not exceed 0.25 MiB/s per provisioned IOPS."
  }
}

variable "encrypted" {
  description = "Whether the EBS volume is encrypted."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "Optional KMS key identifier for EBS encryption; null uses the AWS-managed EBS key."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_id == null ? true : length(trimspace(var.kms_key_id)) > 0
    error_message = "kms_key_id must be null or a non-empty KMS key identifier."
  }

  validation {
    condition     = var.encrypted || var.kms_key_id == null
    error_message = "kms_key_id must not be provided when encrypted is false."
  }
}

variable "tags" {
  description = "Additional tags applied to the EBS volume; standard module tags take precedence."
  type        = map(string)
  default     = {}
}
