# Operation Offer — Nexus Platform

Proyecto práctico para desplegar Nexus Repository en AWS mediante Terraform,
Docker y GitHub Actions.

## Alcance de este checkpoint

- Módulo reutilizable `modules/network` completo.
- Esqueleto del ambiente `environments/dev`.
- Dos Availability Zones.
- Dos subnets públicas y dos privadas.
- Un NAT Gateway para reducir costos en `dev`.

Todavía no incluye ALB, EC2, EBS, RDS, Route 53 ni Nexus.

## Arquitectura de red

- Las subnets públicas tienen una ruta `0.0.0.0/0` hacia el Internet Gateway.
- El NAT Gateway vive en la primera subnet pública y recibe una Elastic IP.
- Las subnets privadas tienen una ruta `0.0.0.0/0` hacia el NAT Gateway.
- El diseño usa un solo NAT en dev intencionalmente. Esto reduce costos, pero
  introduce dependencia de una AZ y tráfico cross-AZ.

## Tu primera tarea

Completa `environments/dev/main.tf` consumiendo el módulo `network`.

El módulo espera estos inputs:

- `project_name`
- `environment`
- `vpc_cidr`
- `public_subnets`
- `private_subnets`
- `tags` (opcional)

Después ejecuta:

```bash
cd environments/dev
terraform fmt -recursive ../..
terraform init
terraform validate
terraform plan
```

No ejecutes `terraform apply` hasta revisar juntos el plan y los costos.

