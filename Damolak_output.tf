# =============================================================
# Damolak_output.tf — Terraform Outputs
# Project : Damolak DevOps Practical Challenge
# =============================================================

# -------------------------------------------------------------
# ECR Repository Outputs
# -------------------------------------------------------------
output "ecr_repository_name" {
  description = "Name of the ECR repository for Damolak app images"
  value       = aws_ecr_repository.damolak_app.name
}

output "ecr_repository_url" {
  description = "Full ECR repository URL for Damolak app images"
  value       = aws_ecr_repository.damolak_app.repository_url
}

# -------------------------------------------------------------
# Application Server Outputs
# -------------------------------------------------------------
output "app_server_public_ip" {
  description = "Elastic IP address attached to Application Server"
  value       = aws_eip.damolak_app_eip.public_ip
}

output "app_server_public_dns" {
  description = "Public DNS name of Application Server"
  value       = aws_instance.damolak_app_server.public_dns
}

output "app_server_private_ip" {
  description = "Private IP address of Application Server"
  value       = aws_instance.damolak_app_server.private_ip
}

output "app_url" {
  description = "Public URL of deployed Damolak application"
  value       = "http://${aws_eip.damolak_app_eip.public_ip}"
}

# -------------------------------------------------------------
# Jenkins Server Outputs
# -------------------------------------------------------------
output "jenkins_server_public_ip" {
  description = "Elastic IP address attached to Jenkins Server"
  value       = aws_eip.damolak_jenkins_eip.public_ip
}

output "jenkins_server_public_dns" {
  description = "Public DNS name of Jenkins Server"
  value       = aws_instance.damolak_jenkins_server.public_dns
}

output "jenkins_server_private_ip" {
  description = "Private IP address of Jenkins Server"
  value       = aws_instance.damolak_jenkins_server.private_ip
}

output "jenkins_url" {
  description = "Public Jenkins dashboard URL"
  value       = "http://${aws_eip.damolak_jenkins_eip.public_ip}:8080"
}

# -------------------------------------------------------------
# Network Outputs (Optional / Helpful)
# -------------------------------------------------------------
output "vpc_id" {
  description = "VPC ID used for Damolak infrastructure"
  value       = aws_vpc.damolak_vpc.id
}

output "public_subnet_id" {
  description = "Public subnet ID used by servers"
  value       = aws_subnet.damolak_public_subnet.id
}
