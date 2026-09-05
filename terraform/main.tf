# Finzla backend platform — ECS Fargate behind a public ALB.
#
# Architecture (see README for the request path and rationale):
#   Internet → HTTPS ALB (public subnets) → ECS Fargate tasks (private subnets)
#
# Resources live in focused files:
#   networking.tf, vpc_endpoints.tf, security_groups.tf
#   kms.tf, logging.tf, ecr.tf, secrets.tf
#   iam.tf, iam_github_oidc.tf
#   alb.tf, ecs.tf, monitoring.tf
#
# Select an environment with:
#   terraform plan -var-file=environments/dev.tfvars
#   terraform plan -var-file=environments/prod.tfvars
#
# Do not store credentials here. AWS auth is the caller's identity
# (local profile or GitHub OIDC). Remote state:
#   terraform init -backend-config=backend.dev.hcl
