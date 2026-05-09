# ── ECR ───────────────────────────────────────────────────────
output "ecr_repository_url" {
  description = "ECR repository URL for Damolak app images"
  value       = aws_ecr_repository.damolak_app.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.damolak_app.name
}