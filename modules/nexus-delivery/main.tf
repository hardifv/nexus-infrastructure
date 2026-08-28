locals {
  name = "${var.project_name}-${var.environment}-nexus-deploy"

  common_tags = merge(var.tags, {
    Name        = local.name
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })

  deployment_script_base64 = filebase64("${path.module}/templates/deploy-nexus.sh.tftpl")
}

resource "aws_volume_attachment" "this" {
  device_name = var.device_name
  volume_id   = var.volume_id
  instance_id = var.instance_id

  force_detach                   = false
  stop_instance_before_detaching = false
}

resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = var.target_group_arn
  target_id        = var.instance_id
  port             = var.nexus_port
}

resource "aws_ssm_document" "this" {
  name            = local.name
  document_type   = "Command"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Deploy or upgrade Nexus Repository on the dev EC2 instance without exposing database credentials."
    parameters = {
      NexusImage = {
        type           = "String"
        description    = "Pinned Sonatype Nexus image reference; latest is rejected by the deployment script."
        allowedPattern = "^sonatype/nexus3:[0-9]+\\.[0-9]+\\.[0-9]+$"
      }
      RDSEndpoint = {
        type        = "String"
        description = "RDS PostgreSQL endpoint including its port."
      }
      RDSDatabaseName = {
        type           = "String"
        description    = "PostgreSQL database owned by the RDS-managed Nexus user."
        allowedPattern = "^[A-Za-z][A-Za-z0-9]*$"
      }
      RDSSecretARN = {
        type           = "String"
        description    = "ARN of the RDS-managed secret retrieved only by the EC2 runtime role."
        allowedPattern = "^arn:(aws|aws-us-gov|aws-cn):secretsmanager:[a-z0-9-]+:[0-9]{12}:secret:rds!db-[A-Za-z0-9/_+=.@!-]+$"
      }
      EBSVolumeID = {
        type           = "String"
        description    = "Persistent EBS volume resolved on the instance through its volume ID."
        allowedPattern = "^vol-[0-9a-f]{8,17}$"
      }
      MountPath = {
        type           = "String"
        default        = "/nexus-data"
        description    = "Persistent Nexus data mount path."
        allowedPattern = "^/nexus-data$"
      }
      NexusPort = {
        type           = "String"
        default        = tostring(var.nexus_port)
        description    = "Host port exposed by the Nexus container."
        allowedPattern = "^[0-9]{1,5}$"
      }
    }
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "deployNexus"
        inputs = {
          timeoutSeconds = "1800"
          runCommand = [
            "umask 077",
            "printf '%s' '${local.deployment_script_base64}' | base64 --decode > /var/tmp/deploy-nexus.sh",
            "chmod 0700 /var/tmp/deploy-nexus.sh",
            "/var/tmp/deploy-nexus.sh '{{ NexusImage }}' '{{ RDSEndpoint }}' '{{ RDSDatabaseName }}' '{{ RDSSecretARN }}' '{{ EBSVolumeID }}' '{{ MountPath }}' '{{ NexusPort }}'",
            "rm -f /var/tmp/deploy-nexus.sh",
          ]
        }
      }
    ]
  })

  tags = local.common_tags
}
