resource "aws_sns_topic" "ops" {
  name              = "${local.name_prefix}-ops-alerts"
  kms_master_key_id = aws_kms_key.platform.id
}

resource "aws_sns_topic_policy" "ops" {
  arn = aws_sns_topic.ops.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.ops.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "ops_email" {
  count = var.alarm_email == "" ? 0 : 1

  topic_arn = aws_sns_topic.ops.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${local.name_prefix}-unhealthy-hosts"
  alarm_description   = "ALB has unhealthy ECS targets. Customers may see 503s."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.ops.arn]
  ok_actions          = [aws_sns_topic.ops.arn]

  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "target_5xx" {
  alarm_name          = "${local.name_prefix}-target-5xx"
  alarm_description   = "Application is returning HTTP 5xx through the ALB."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.ops.arn]
  ok_actions          = [aws_sns_topic.ops.arn]

  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }
}

resource "aws_cloudwatch_dashboard" "app" {
  dashboard_name = "${local.name_prefix}-api"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "Target 5xx"
          region = data.aws_region.current.name
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.app.arn_suffix, "TargetGroup", aws_lb_target_group.app.arn_suffix, { stat = "Sum" }],
          ]
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "Target response time"
          region = data.aws_region.current.name
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.app.arn_suffix, "TargetGroup", aws_lb_target_group.app.arn_suffix, { stat = "p95" }],
          ]
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "Unhealthy hosts"
          region = data.aws_region.current.name
          metrics = [
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", aws_lb.app.arn_suffix, "TargetGroup", aws_lb_target_group.app.arn_suffix, { stat = "Maximum" }],
          ]
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "CPU utilisation"
          region = data.aws_region.current.name
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.app.name, "ServiceName", aws_ecs_service.app.name, { stat = "Average" }],
          ]
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "Memory utilisation"
          region = data.aws_region.current.name
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.app.name, "ServiceName", aws_ecs_service.app.name, { stat = "Average" }],
          ]
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "Running task count"
          region = data.aws_region.current.name
          metrics = [
            ["ECS/ContainerInsights", "RunningTaskCount", "ClusterName", aws_ecs_cluster.app.name, "ServiceName", aws_ecs_service.app.name, { stat = "Average" }],
          ]
          period = 60
        }
      }
    ]
  })
}
