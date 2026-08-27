variable "project_name" {
  description = "Project name used in deterministic Nexus EC2 IAM resource names and tags."
  type        = string

  validation {
    condition     = length(var.project_name) <= 30 && can(regex("^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$", var.project_name))
    error_message = "project_name must be 1-30 lowercase characters, start with a letter, and contain only letters, numbers, or single hyphens."
  }
}

variable "environment" {
  description = "Environment name used in deterministic Nexus EC2 IAM resource names and tags."
  type        = string

  validation {
    condition     = length(var.environment) <= 15 && can(regex("^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$", var.environment))
    error_message = "environment must be 1-15 lowercase characters, start with a letter, and contain only letters, numbers, or single hyphens."
  }
}

variable "master_user_secret_arn" {
  description = "ARN of the RDS-managed Secrets Manager secret readable by the Nexus EC2 runtime role."
  type        = string

  validation {
    condition     = can(regex("^arn:(?:aws|aws-us-gov|aws-cn):secretsmanager:[a-z0-9-]+:[0-9]{12}:secret:[A-Za-z0-9/_+=.@-]+$", var.master_user_secret_arn))
    error_message = "master_user_secret_arn must be a plausible AWS Secrets Manager secret ARN."
  }
}

variable "tags" {
  description = "Additional tags applied to taggable IAM resources; standard module tags take precedence."
  type        = map(string)
  default     = {}
}
