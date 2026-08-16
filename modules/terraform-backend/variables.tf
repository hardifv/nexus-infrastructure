variable "bucket_name" {
  description = "Globally unique name for the Terraform state S3 bucket."
  type        = string

  validation {
    condition = (
      length(var.bucket_name) >= 3 &&
      length(var.bucket_name) <= 63 &&
      can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    )
    error_message = "bucket_name must be 3-63 characters and use lowercase letters, numbers, periods, or hyphens, starting and ending with a letter or number."
  }
}

variable "project_name" {
  description = "Project name used in resource tags."
  type        = string

  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "project_name cannot be empty."
  }
}

variable "environment" {
  description = "Environment or scope associated with the Terraform state bucket."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment cannot be empty."
  }
}

variable "tags" {
  description = "Additional tags applied to the Terraform state bucket."
  type        = map(string)
  default     = {}
}
