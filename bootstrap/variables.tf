variable "aws_region" {
  description = "AWS region used by the dev environment."
  type        = string
}

variable "bucket_name" {
  description = "Globally unique name for the Terraform state S3 bucket."
  type        = string

}

variable "project_name" {
  description = "Project name used in resource tags."
  type        = string

}

variable "managed_project_name" {
  description = "Project name used by the dev resources managed through the Terraform IAM policies."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-]*$", var.managed_project_name))
    error_message = "managed_project_name must start with a letter or number and contain only letters, numbers, or hyphens."
  }
}

variable "environment" {
  description = "Environment or scope associated with the Terraform state bucket."
  type        = string


}

variable "github_repository" {
  description = "GitHub repository in owner/repository format."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must use owner/repository format."
  }
}

variable "github_owner_id" {
  description = "Immutable numeric GitHub owner ID used in OIDC subject claims."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_owner_id))
    error_message = "github_owner_id must contain only numeric characters."
  }
}

variable "github_repository_id" {
  description = "Immutable numeric GitHub repository ID used in OIDC subject claims."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_repository_id))
    error_message = "github_repository_id must contain only numeric characters."
  }
}
