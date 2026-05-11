# =============================================================
# Damolak_ecr.tf — Elastic Container Registry
# Project : Damolak DevOps Practical Challenge
# Stores Docker images for Jenkins CI/CD deployments
# =============================================================

# ── ECR Repository ────────────────────────────────────────────
resource "aws_ecr_repository" "damolak_app" {
  name                 = "${var.project_name}-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${var.project_name}-app-ecr"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ── ECR Lifecycle Policy ──────────────────────────────────────
resource "aws_ecr_lifecycle_policy" "damolak_app" {
  repository = aws_ecr_repository.damolak_app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"

        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }

        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ── Optional Repository Policy (same account access) ─────────
resource "aws_ecr_repository_policy" "damolak_app" {
  repository = aws_ecr_repository.damolak_app.name

  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Sid    = "AllowSameAccountPullPush"
        Effect = "Allow"

        Principal = "*"

        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  })
}