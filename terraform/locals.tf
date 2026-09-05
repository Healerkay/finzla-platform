locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnet_cidrs  = [cidrsubnet(var.vpc_cidr, 8, 0), cidrsubnet(var.vpc_cidr, 8, 1)]
  private_subnet_cidrs = [cidrsubnet(var.vpc_cidr, 8, 10), cidrsubnet(var.vpc_cidr, 8, 11)]

  github_oidc_provider_arn = try(aws_iam_openid_connect_provider.github[0].arn, var.github_oidc_provider_arn)

  # CI builds a real URI; keep a valid placeholder so validate/plan work
  # before the first image exists.
  container_image = var.container_image != "" ? var.container_image : "${aws_ecr_repository.app.repository_url}:latest"

  https_configured = var.enable_https && var.acm_certificate_arn != ""
}

check "https_requires_certificate" {
  assert {
    condition     = !var.enable_https || var.acm_certificate_arn != ""
    error_message = "enable_https is true but acm_certificate_arn is empty."
  }
}

check "oidc_provider_arn_when_not_created" {
  assert {
    condition     = var.create_github_oidc_provider || var.github_oidc_provider_arn != ""
    error_message = "Provide github_oidc_provider_arn when create_github_oidc_provider is false."
  }
}
