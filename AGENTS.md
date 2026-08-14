# Operation Offer — Nexus Infrastructure

## Purpose

Build a realistic end-to-end DevOps project inspired by the user's Equifax experience while applying modern best practices.

The goal is to understand and explain every architectural decision during technical interviews, not merely generate infrastructure.

This project simulates a professional environment. Do not claim that every implementation detail was used at Equifax.

## Fixed architecture standard

The architecture described in this file is the established standard for the project.

Do not change repository boundaries, environment strategy, resource ownership, or deployment approach unless the user explicitly approves an architectural change.

If a proposed change conflicts with this standard, explain the conflict before modifying code.

## Environments

The project has three environments:

1. dev
2. staging
3. production

Build and validate dev completely before promoting the design to staging and production.

Do not create staging or production until the dev implementation is functional and reviewed.

Each environment must have:

- Separate configuration.
- Separate Terraform state.
- Independent deployment controls.
- The same reusable modules.
- No copied resource implementations between environments.

## Fixed repository boundaries

This project uses exactly two repositories.

### 1. nexus-infrastructure

This is the current repository.

Responsibilities:

- Terraform reusable modules.
- Environment composition.
- VPC and networking.
- Security Groups.
- Application Load Balancer.
- Target Groups and listeners.
- Route 53.
- IAM roles and instance profiles.
- RDS PostgreSQL.
- Persistent EBS storage.
- Launch Templates.
- EC2 infrastructure.
- CloudWatch infrastructure.
- Terraform state and backend configuration.
- Infrastructure GitHub Actions workflows.

### 2. nexus-delivery

This repository will be created later, after the dev infrastructure is functional.

Responsibilities:

- Consume an existing corporate golden AMI; never build the golden AMI.
- Install and configure Docker.
- Nexus container configuration.
- Versioned Nexus image deployment.
- Blue/green EC2 replacement orchestration.
- Controlled Nexus shutdown and startup.
- EBS detach and attach operations.
- Target registration and traffic switching.
- Health checks and smoke tests.
- Rollback.
- Promotion of the same artifact from dev to staging to production.
- Delivery GitHub Actions workflows.

Do not merge these responsibilities into one repository.

Do not create a third repository unless the user explicitly approves a new architecture decision.

## AWS architecture

- AWS infrastructure is managed with Terraform.
- The Application Load Balancer runs across public subnets.
- EC2 instances run in private subnets.
- Nexus runs as a Docker container on EC2.
- A NAT Gateway provides outbound access for private instances.
- Route 53 points the Nexus DNS record to the ALB.
- ACM provides the TLS certificate used by the ALB.
- TLS terminates at the ALB.
- The ALB forwards traffic to Nexus on its application port.
- The ALB Security Group accepts traffic from approved client networks.
- The EC2 Security Group accepts Nexus traffic only from the ALB Security Group.
- Private EC2 instances should be managed using AWS Systems Manager rather than public SSH.
- Nexus metadata uses RDS PostgreSQL.
- Nexus persistent application data and artifacts use an EBS volume.
- Long-lived data resources must survive EC2 replacement.
- Backups and recovery controls will be added deliberately.

## Networking standard

The dev network uses:

- One VPC.
- Two Availability Zones.
- Two public subnets.
- Two private subnets.
- One Internet Gateway.
- One NAT Gateway located in a public subnet.
- One Elastic IP for the NAT Gateway.
- Public route tables with `0.0.0.0/0` routed to the Internet Gateway.
- Private route tables with `0.0.0.0/0` routed to the NAT Gateway.

Dev intentionally uses one NAT Gateway to reduce cost.

This introduces:

- A dependency on one Availability Zone.
- Possible cross-AZ traffic.
- Lower availability than a NAT Gateway per AZ.

Production availability will be evaluated later without changing dev prematurely.

## Blue/green standard

Nexus is stateful.

The project accepts controlled downtime during blue/green replacement because one persistent EBS volume must move between EC2 instances.

The expected high-level flow is:

1. Create the green EC2 instance from the approved Launch Template and golden AMI.
2. Install and configure Docker.
3. Keep green out of production traffic.
4. Stop Nexus cleanly on blue.
5. Unmount and detach the persistent EBS volume from blue.
6. Attach and mount the EBS volume on green.
7. Start the versioned Nexus container on green.
8. Run health checks and smoke tests.
9. Register green with the Target Group.
10. Shift traffic to green.
11. Keep blue available temporarily for rollback when practical.
12. Remove blue only after validation.

Because EBS volumes are tied to an Availability Zone, blue and green must be compatible with the volume's Availability Zone.

Do not describe this design as zero downtime or active-active high availability.

## Terraform repository approach

Use reusable Terraform modules under:

`modules/`

Use environment composition under:

`environments/`

Expected environments:

- `environments/dev`
- `environments/staging`
- `environments/production`

Rules:

- Modules define reusable resources.
- Environment directories consume modules and provide environment-specific values.
- Do not copy full Terraform resource definitions between environments.
- Keep state and configuration separate per environment.
- Use explicit module inputs and outputs.
- Use consistent naming and tagging.
- Avoid hardcoded account-specific identifiers.
- Do not place credentials or secrets in Terraform files.
- Remote state will be added later through a deliberate bootstrap phase.
- Do not introduce Terraform workspaces unless the architecture is explicitly reconsidered.

## Automation standard

GitHub Actions will eventually use:

- AWS OIDC authentication.
- Short-lived AWS credentials.
- Least-privilege IAM roles.
- Pull request validation.
- `terraform fmt`.
- `terraform validate`.
- Terraform plan review.
- GitHub Environments.
- Manual approvals for sensitive environments.
- Separate controls for dev, staging, and production.
- Promotion of the same immutable application artifact.
- No rebuilding the Nexus artifact separately for each environment.

Do not implement all automation before the dev infrastructure is functional.

## Current checkpoint

The current repository is `nexus-infrastructure`.

Current status:

- `modules/network` already exists.
- Only `environments/dev` exists.
- `environments/dev/main.tf` is intentionally incomplete.
- `environments/dev/outputs.tf` is intentionally incomplete.
- The network module is not yet consumed by the dev environment.
- A real `terraform.tfvars` has not been created.
- The remote backend has not been configured.
- Terraform has not yet been applied.
- Staging and production must not be created yet.
- ALB, EC2, RDS, EBS, Route 53, IAM, and application delivery are outside the current checkpoint.

## Collaboration model

Act as the project's Tech Lead and interviewer.

The Tech Lead should:

- Define the architecture and engineering standards.
- Build or help build reusable modules.
- Explain important tradeoffs.
- Review the user's environment composition.
- Identify risks before infrastructure is applied.
- Keep the technical story consistent.
- Ask interview questions only when they support understanding.

The user should:

- Consume reusable modules from environment directories.
- Define environment-specific configuration.
- Connect module inputs and outputs.
- Review Terraform plans.
- Explain the purpose, flow, and benefit of each decision.
- Complete small implementation tasks with guidance.

## Working rules

- Work in small, reviewable checkpoints.
- Do not implement the entire project unless explicitly requested.
- Explain purpose and flow before changing code.
- Before editing, state exactly which files will change.
- Do not modify unrelated files.
- Do not create staging or production prematurely.
- Do not apply infrastructure without explicit user approval.
- Never run destructive Terraform commands without explicit approval.
- Never run `terraform destroy` without explicit approval.
- Never approve a plan containing unexpected resource destruction.
- Run only safe validation commands that are available.
- Review command output before proposing the next action.
- Distinguish facts from assumptions.
- Do not invent company history or claim simulated decisions were used at Equifax.
- When the user is assigned a task, do not immediately provide the completed answer unless requested.
- If the user becomes blocked by syntax, provide a focused example rather than the entire project.
- Help the user explain decisions using problem, solution, and benefit.
- Communicate in clear Spanish while keeping technical identifiers and terminology in English.
