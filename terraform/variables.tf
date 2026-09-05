variable "aws_region" {
  description = "AWS region for this environment."
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name. Used in resource names and tags."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "project_name" {
  description = "Short project name used in resource naming."
  type        = string
  default     = "finzla"
}

variable "vpc_cidr" {
  description = "VPC IPv4 CIDR."
  type        = string
  default     = "10.40.0.0/16"
}

variable "enable_nat_gateway" {
  description = "Create a single NAT Gateway for private-subnet internet egress. Prefer VPC endpoints for AWS APIs; enable this only if the app needs the public internet."
  type        = bool
  default     = false
}

variable "enable_https" {
  description = "Serve HTTPS on the ALB and redirect HTTP to HTTPS. Requires acm_certificate_arn."
  type        = bool
  default     = false
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN in this region for the ALB HTTPS listener. Required when enable_https is true."
  type        = string
  default     = ""

  validation {
    condition     = var.acm_certificate_arn == "" || startswith(var.acm_certificate_arn, "arn:aws:acm:")
    error_message = "acm_certificate_arn must be empty or an ACM ARN."
  }
}

variable "container_image" {
  description = "Full image URI to run (ECR URI plus tag or digest). CI overwrites this on deploy."
  type        = string
  default     = ""
}

variable "container_port" {
  description = "Application listen port inside the container."
  type        = number
  default     = 8000
}

variable "app_env" {
  description = "Value for the APP_ENV container environment variable."
  type        = string
  default     = "development"
}

variable "desired_count" {
  description = "Desired ECS task count."
  type        = number
  default     = 2
}

variable "task_cpu" {
  description = "Fargate task CPU units (256, 512, 1024, ...)."
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate task memory (MiB)."
  type        = number
  default     = 512
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for application and VPC flow logs."
  type        = number
  default     = 30
}

variable "alarm_email" {
  description = "Email subscribed to the ops SNS topic. Leave empty to skip the subscription."
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_org" {
  description = "GitHub organisation or user that owns the application repository."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without org)."
  type        = string
}

variable "github_deploy_environment" {
  description = "GitHub Environment name required on the OIDC sub claim for deploys (e.g. production)."
  type        = string
}

variable "create_github_oidc_provider" {
  description = "Create the GitHub OIDC provider in this account. Set false and pass github_oidc_provider_arn if one already exists."
  type        = bool
  default     = true
}

variable "github_oidc_provider_arn" {
  description = "Existing GitHub OIDC provider ARN when create_github_oidc_provider is false."
  type        = string
  default     = ""
}

variable "allowed_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the ALB. Restrict in production if the service is not public."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
