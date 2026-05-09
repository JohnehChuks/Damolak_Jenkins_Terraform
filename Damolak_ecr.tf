# =============================================================
# Damolak_ecr.tf — Elastic Container Registry
# Project : Damolak DevOps Challenge
# =============================================================

# ── ECR Repository ────────────────────────────────────────────
resource "aws_ecr_repository" "damolak_app" {
  name                 = "${var.project_name}-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-app-ecr"
  }
}

# ── ECR Lifecycle Policy ──────────────────────────────────────
resource "aws_ecr_lifecycle_policy" "damolak_app" {
  repository = aws_ecr_repository.damolak_app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}