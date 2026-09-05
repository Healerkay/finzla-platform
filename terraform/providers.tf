provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }

  # Credentials must never be hard-coded. Use AWS_PROFILE, an instance/
  # task role, or GitHub Actions OIDC. The empty default_tags block above
  # is not a credential source.
}
