output "ssm_document_name" {
  description = "Name of the SSM document used to deploy or upgrade Nexus."
  value       = aws_ssm_document.this.name
}
