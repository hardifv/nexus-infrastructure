output "db_instance_id" {
  description = "Identifier of the RDS PostgreSQL instance."
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "ARN of the RDS PostgreSQL instance."
  value       = aws_db_instance.this.arn
}

output "endpoint" {
  description = "Connection endpoint including the port of the RDS PostgreSQL instance."
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "Hostname of the RDS PostgreSQL instance."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Port of the RDS PostgreSQL instance."
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Name of the initial PostgreSQL database."
  value       = aws_db_instance.this.db_name
}

output "master_username" {
  description = "Master username of the RDS PostgreSQL instance."
  value       = aws_db_instance.this.username
}

output "master_user_secret_arn" {
  description = "ARN of the RDS-managed Secrets Manager secret containing the master credentials."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "db_subnet_group_name" {
  description = "Name of the RDS DB subnet group."
  value       = aws_db_subnet_group.this.name
}
