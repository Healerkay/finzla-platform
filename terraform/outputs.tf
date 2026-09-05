output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (ALB)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (ECS tasks)."
  value       = aws_subnet.private[*].id
}

output "alb_dns_name" {
  description = "Public ALB DNS name (application ingress)."
  value       = aws_lb.app.dns_name
}

output "alb_https_url" {
  description = "HTTPS URL when a certificate is configured; otherwise HTTP."
  value       = local.https_configured ? "https://${aws_lb.app.dns_name}" : "http://${aws_lb.app.dns_name}"
}

output "ecr_repository_url" {
  description = "ECR repository to push the application image."
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.app.name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.app.name
}

output "cloudwatch_log_group" {
  description = "Application log group. Query streams under /ecs/<prefix>/api/*."
  value       = aws_cloudwatch_log_group.app.name
}

output "sns_alerts_topic_arn" {
  description = "SNS topic for CloudWatch alarms."
  value       = aws_sns_topic.ops.arn
}

output "github_ci_role_arn" {
  description = "OIDC role for GitHub Actions image build/push."
  value       = aws_iam_role.github_ci.arn
}

output "github_plan_role_arn" {
  description = "OIDC role for GitHub Actions terraform plan on pull requests."
  value       = aws_iam_role.github_plan.arn
}

output "github_deploy_role_arn" {
  description = "OIDC role for GitHub Actions ECS deploy. Restricted to the GitHub Environment."
  value       = aws_iam_role.github_deploy.arn
}

output "app_secret_arn" {
  description = "Secrets Manager ARN. Populate versions out of band."
  value       = aws_secretsmanager_secret.app.arn
}
