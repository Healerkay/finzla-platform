resource "aws_secretsmanager_secret" "app" {
  name                    = "${local.name_prefix}/app"
  description             = "Application secrets. Values are set out of band, never in Terraform."
  kms_key_id              = aws_kms_key.platform.arn
  recovery_window_in_days = var.environment == "prod" ? 30 : 0

  tags = {
    Name = "${local.name_prefix}-app-secret"
  }
}

# No aws_secretsmanager_secret_version here on purpose: putting secret
# values in *.tf or tfvars would copy them into state. Populate via the
# AWS console, CLI, or a restricted CI job that writes the version only.
