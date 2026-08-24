variable "project_name" {
  description = "Project name used in deterministic RDS resource names and tags."
  type        = string

  validation {
    condition     = length(var.project_name) <= 30 && can(regex("^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$", var.project_name))
    error_message = "project_name must be 1-30 lowercase characters, start with a letter, and contain only letters, numbers, or single hyphens."
  }
}

variable "environment" {
  description = "Environment name used in deterministic RDS resource names and tags."
  type        = string

  validation {
    condition     = length(var.environment) <= 15 && can(regex("^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$", var.environment))
    error_message = "environment must be 1-15 lowercase characters, start with a letter, and contain only letters, numbers, or single hyphens."
  }
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used by the RDS DB subnet group."
  type        = set(string)

  validation {
    condition = (
      length(var.private_subnet_ids) >= 2 &&
      alltrue([for subnet_id in var.private_subnet_ids : can(regex("^subnet-[0-9a-f]{8,17}$", subnet_id))])
    )
    error_message = "private_subnet_ids must contain at least two valid AWS subnet IDs."
  }
}

variable "rds_security_group_id" {
  description = "ID of the Security Group attached to the RDS instance."
  type        = string

  validation {
    condition     = can(regex("^sg-[0-9a-f]{8,17}$", var.rds_security_group_id))
    error_message = "rds_security_group_id must be a valid AWS Security Group ID."
  }
}

variable "engine_version" {
  description = "PostgreSQL engine version used by the RDS instance."
  type        = string
  default     = "16"

  validation {
    condition     = can(regex("^[0-9]+(?:\\.[0-9]+){0,2}$", var.engine_version))
    error_message = "engine_version must be a PostgreSQL numeric version such as 16 or 16.4."
  }
}

variable "instance_class" {
  description = "RDS DB instance class."
  type        = string
  default     = "db.t4g.micro"

  validation {
    condition     = can(regex("^db\\.[a-z0-9]+(?:[.-][a-z0-9]+)*$", var.instance_class))
    error_message = "instance_class must be a valid RDS instance class beginning with db."
  }
}

variable "database_name" {
  description = "Name of the initial PostgreSQL database."
  type        = string
  default     = "nexus"

  validation {
    condition     = length(var.database_name) >= 1 && length(var.database_name) <= 63 && can(regex("^[A-Za-z][A-Za-z0-9]*$", var.database_name))
    error_message = "database_name must be 1-63 alphanumeric characters and begin with a letter."
  }
}

variable "master_username" {
  description = "Master username for PostgreSQL; its password is managed by RDS in Secrets Manager."
  type        = string
  default     = "nexus_admin"

  validation {
    condition     = length(var.master_username) >= 1 && length(var.master_username) <= 63 && can(regex("^[A-Za-z][A-Za-z0-9_]*$", var.master_username))
    error_message = "master_username must be 1-63 letters, numbers, or underscores and begin with a letter."
  }
}

variable "port" {
  description = "Port on which PostgreSQL accepts connections."
  type        = number
  default     = 5432

  validation {
    condition     = var.port == floor(var.port) && var.port >= 1 && var.port <= 65535
    error_message = "port must be an integer between 1 and 65535."
  }
}

variable "allocated_storage" {
  description = "Initial allocated database storage in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage == floor(var.allocated_storage) && var.allocated_storage > 0
    error_message = "allocated_storage must be a positive integer."
  }
}

variable "max_allocated_storage" {
  description = "Maximum database storage in GiB when storage autoscaling is enabled."
  type        = number
  default     = 100

  validation {
    condition     = var.max_allocated_storage == floor(var.max_allocated_storage) && var.max_allocated_storage >= var.allocated_storage
    error_message = "max_allocated_storage must be an integer not smaller than allocated_storage."
  }
}

variable "storage_type" {
  description = "RDS storage type; this module supports gp3 only."
  type        = string
  default     = "gp3"

  validation {
    condition     = var.storage_type == "gp3"
    error_message = "storage_type must be gp3."
  }
}

variable "multi_az" {
  description = "Whether the RDS instance uses a Multi-AZ deployment."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days that automated backups are retained."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period == floor(var.backup_retention_period) && var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be an integer between 0 and 35 days."
  }
}

variable "deletion_protection_enabled" {
  description = "Whether deletion protection is enabled for the RDS instance."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Whether RDS skips the final snapshot when the instance is deleted."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Whether eligible RDS modifications are applied immediately instead of during the maintenance window."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
