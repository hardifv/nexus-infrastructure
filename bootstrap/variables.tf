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
