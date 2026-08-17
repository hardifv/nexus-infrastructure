variable "github_repository" {
  description = "GitHub repository in owner/repository format."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must use owner/repository format."
  }
}

variable "project_name" {
  description = "Project name used in IAM role names and resource tags."
  type        = string

  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "project_name cannot be empty."
  }
}

variable "environment_name" {
  description = "GitHub Environment trusted by the Terraform apply role."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+$", var.environment_name))
    error_message = "environment_name must contain only letters, numbers, periods, underscores, or hyphens."
  }
}

variable "tags" {
  description = "Additional tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}

variable "state_bucket_arn" {
  description = "ARN of the S3 Terraform state bucket."
  type        = string

  validation {
    condition     = can(regex("^arn:(aws|aws-us-gov|aws-cn):s3:::[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.state_bucket_arn))
    error_message = "state_bucket_arn must be a valid S3 bucket ARN."
  }
}

variable "state_key" {
  description = "S3 object key used for the dev Terraform state."
  type        = string
  default     = "nexus/dev/terraform.tfstate"

  validation {
    condition     = length(trimspace(var.state_key)) > 0 && !startswith(var.state_key, "/")
    error_message = "state_key cannot be empty or start with a slash."
  }
}

variable "aws_region" {
  description = "AWS region in which EC2 network operations are allowed."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS region name."
  }
}
