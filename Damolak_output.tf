# =============================================================
# Damolak_output.tf — Terraform Outputs
# Project : Damolak DevOps Practical Challenge
# =============================================================

# ── ECR Repository ────────────────────────────────────────────
output "ecr_repository_url" {
  description = "ECR repository URL for Damolak app images"
  value       = aws_ecr_repository.damolak_app.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.damolak_app.name
}

# ── Application Server ───────────────────────────────────────
output "app_server_public_ip" {
  description = "Elastic IP address of App Server"
  value       = aws_eip.damolak_app_eip.public_ip
}

output "app_server_public_dns" {
  description = "Public DNS of App Server"
  value       = aws_instance.damolak_app_server.public_dns
}

output "app_url" {
  description = "Application URL"
  value       = "http://${aws_eip.damolak_app_eip.public_ip}"
}

# ── Jenkins Server ────────────────────────────────────────────
output "jenkins_server_public_ip" {
  description = "Elastic IP address of Jenkins Server"
  value       = aws_eip.damolak_jenkins_eip.public_ip
}

output "jenkins_server_public_dns" {
  description = "Public DNS of Jenkins Server"
  value       = aws_instance.damolak_jenkins_server.public_dns
}

output "jenkins_url" {
  description = "Jenkins Web URL"
  value       = "http://${aws_eip.damolak_jenkins_eip.public_ip}:8080"
}