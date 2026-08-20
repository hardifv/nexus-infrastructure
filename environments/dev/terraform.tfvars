aws_region   = "us-east-1"
project_name = "nexus-platform"
environment  = "dev"
vpc_cidr     = "10.10.0.0/16"

public_subnets = {
  us-east-1a = "10.10.0.0/24"
  us-east-1b = "10.10.1.0/24"
}

private_subnets = {
  us-east-1a = "10.10.10.0/24"
  us-east-1b = "10.10.11.0/24"
}

allowed_client_cidrs = ["0.0.0.0/0"]