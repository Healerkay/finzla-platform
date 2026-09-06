resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHub's published CA thumbprints. The TLS handshake chain is not a
  # reliable source and wrong values reject AssumeRoleWithWebIdentity.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
}

data "aws_iam_policy_document" "github_oidc_assume" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity",
      "sts:TagSession",
    ]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_org}/${var.github_repo}:*",
        "repo:${var.github_org}@*/${var.github_repo}@*:*",
      ]
    }
  }
}

# Push images from CI. Cannot update ECS or pass IAM roles.
resource "aws_iam_role" "github_ci" {
  name               = "${local.name_prefix}-github-ci"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume.json
}

resource "aws_iam_role_policy" "github_ci" {
  name = "ecr-push"
  role = aws_iam_role.github_ci.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AuthToken"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "PushThisRepo"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:DescribeRepositories",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
        ]
        Resource = aws_ecr_repository.app.arn
      },
      {
        Sid    = "EncryptImages"
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey",
        ]
        Resource = aws_kms_key.platform.arn
      }
    ]
  })
}

data "aws_iam_policy_document" "github_deploy_assume" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity",
      "sts:TagSession",
    ]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_org}/${var.github_repo}:environment:${var.github_deploy_environment}",
        "repo:${var.github_org}@*/${var.github_repo}@*:environment:${var.github_deploy_environment}",
      ]
    }
  }
}

# Read-only + remote-state lock so pull requests can run terraform plan.
resource "aws_iam_role" "github_plan" {
  name               = "${local.name_prefix}-github-plan"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume.json
}

resource "aws_iam_role_policy" "github_plan" {
  name = "terraform-plan"
  role = aws_iam_role.github_plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RemoteState"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetEncryptionConfiguration",
          "s3:GetBucketPolicy",
          "s3:GetBucketTagging",
          "s3:GetBucketLogging",
          "s3:GetLifecycleConfiguration",
          "s3:GetBucketAcl",
        ]
        Resource = "arn:aws:s3:::finzla-terraform-state-${data.aws_caller_identity.current.account_id}"
      },
      {
        Sid      = "RemoteStateObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::finzla-terraform-state-${data.aws_caller_identity.current.account_id}/platform/${var.environment}/*"
      },
      {
        Sid    = "StateLock"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable",
        ]
        Resource = "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/finzla-terraform-locks"
      },
      {
        Sid    = "DecryptStateAndPlatform"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey",
        ]
        Resource = [
          aws_kms_key.platform.arn,
          data.aws_kms_alias.tf_state.target_key_arn,
        ]
      },
      {
        Sid    = "RefreshForPlan"
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetDashboard",
          "cloudwatch:ListTagsForResource",
          "ec2:Describe*",
          "ecr:Describe*",
          "ecr:GetLifecyclePolicy",
          "ecr:GetRepositoryPolicy",
          "ecr:ListTagsForResource",
          "ecs:Describe*",
          "ecs:List*",
          "elasticloadbalancing:Describe*",
          "iam:GetOpenIDConnectProvider",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "kms:GetKeyPolicy",
          "kms:GetKeyRotationStatus",
          "kms:ListAliases",
          "kms:ListResourceTags",
          "logs:DescribeLogGroups",
          "logs:ListTagsForResource",
          "s3:Get*",
          "s3:ListBucket",
          "secretsmanager:DescribeSecret",
          "sns:GetTopicAttributes",
          "sns:ListTagsForResource",
          "sts:GetCallerIdentity",
        ]
        Resource = "*"
      }
    ]
  })
}

# Most sensitive role in this stack: can change what production runs.
# Bound to one GitHub Environment (branch protection + required reviewers).
resource "aws_iam_role" "github_deploy" {
  name               = "${local.name_prefix}-github-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_deploy_assume.json
}

resource "aws_iam_role_policy" "github_deploy" {
  name = "ecs-deploy"
  role = aws_iam_role.github_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "UpdateThisService"
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
        ]
        Resource = aws_ecs_service.app.id
      },
      {
        Sid      = "ListTasksOnCluster"
        Effect   = "Allow"
        Action   = ["ecs:ListTasks"]
        Resource = aws_ecs_cluster.app.arn
      },
      {
        Sid      = "DescribeTasks"
        Effect   = "Allow"
        Action   = ["ecs:DescribeTasks"]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "ecs:cluster" = aws_ecs_cluster.app.arn
          }
        }
      },
      {
        Sid    = "RegisterAndDescribeTaskDefinition"
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
        ]
        Resource = "*"
      },
      {
        Sid    = "PassTaskRolesOnly"
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = [
          aws_iam_role.ecs_execution.arn,
          aws_iam_role.ecs_task.arn,
        ]
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      },
      {
        Sid    = "ReadElbHealth"
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeLoadBalancers",
        ]
        Resource = "*"
      },
      {
        Sid      = "TagTaskDefinition"
        Effect   = "Allow"
        Action   = ["ecs:TagResource"]
        Resource = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-definition/${aws_ecs_task_definition.app.family}:*"
      }
    ]
  })
}
