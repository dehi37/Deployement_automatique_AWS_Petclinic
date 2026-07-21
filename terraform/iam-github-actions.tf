# iam-github-actions.tf
################################################################################
# IAM Role pour GitHub Actions (OIDC - sans clés statiques)
################################################################################

data "tls_certificate" "github_oidc" {
  url = "https://token.actions.githubusercontent.com"
}

# Fournisseur OIDC pour GitHub
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_oidc.certificates[0].sha1_fingerprint]
}

# Rôle IAM pour GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-github-actions-role"
  }
}

# Politique pour le rôle GitHub Actions
resource "aws_iam_role_policy" "github_actions" {
  name = "${var.project_name}-github-actions-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Terraform State
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning"
        ]
        Resource = [
          "arn:aws:s3:::petclinic-tfstate-2026",
          "arn:aws:s3:::petclinic-tfstate-2026/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:*:table/petclinic-tf-locks"
      },
      # Terraform apply sur toutes les ressources
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "ecs:*",
          "ecr:*",
          "rds:*",
          "iam:*",
          "secretsmanager:*",
          "cloudwatch:*",
          "logs:*",
          "sns:*",
          "s3:*",
          "elasticloadbalancing:*",
          "wafv2:*",
          "cloudfront:*",
          "budgets:*",
          "kms:*"
        ]
        Resource = "*"
      },
      # ECR login pour l'application
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      }
    ]
  })
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}