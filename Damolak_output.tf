# =============================================================
# Damolak_output.tf — Terraform Outputs
# Project : Damolak DevOps Practical Challenge
# =============================================================

# ── VPC ───────────────────────────────────────────────────────
output "vpc_id" {
  description = "ID of the shared Damolak VPC"
  value       = aws_vpc.damolak_vpc.id
}

output "public_subnet_id" {
  description = "ID of the shared public subnet"
  value       = aws_subnet.damolak_public_subnet.id
}

# ── Jenkins Server ────────────────────────────────────────────
output "jenkins_instance_id" {
  description = "EC2 Instance ID of the Jenkins server"
  value       = aws_instance.damolak_jenkins_server.id
}

output "jenkins_private_ip" {
  description = "Private IP of the Jenkins server"
  value       = aws_instance.damolak_jenkins_server.private_ip
}

output "jenkins_elastic_ip" {
  description = "Public Elastic IP of the Jenkins server"
  value       = aws_eip.damolak_jenkins_eip.public_ip
}

output "jenkins_url" {
  description = "Jenkins Web UI URL"
  value       = "http://${aws_eip.damolak_jenkins_eip.public_ip}:8080"
}

output "jenkins_ssh_command" {
  description = "SSH command to connect to the Jenkins server"
  value       = "ssh -i keys/${var.jenkins_keypair_name}.pem ubuntu@${aws_eip.damolak_jenkins_eip.public_ip}"
}

# ── App Server ────────────────────────────────────────────────
output "app_instance_id" {
  description = "EC2 Instance ID of the application server"
  value       = aws_instance.damolak_app_server.id
}

output "app_private_ip" {
  description = "Private IP of the application server"
  value       = aws_instance.damolak_app_server.private_ip
}

output "app_elastic_ip" {
  description = "Public Elastic IP of the application server"
  value       = aws_eip.damolak_app_eip.public_ip
}

output "app_url" {
  description = "Application server public URL"
  value       = "http://${aws_eip.damolak_app_eip.public_ip}"
}

output "app_ssh_command" {
  description = "SSH command to connect to the application server"
  value       = "ssh -i keys/${var.app_keypair_name}.pem ubuntu@${aws_eip.damolak_app_eip.public_ip}"
}

# ── Security Groups ───────────────────────────────────────────
output "jenkins_sg_id" {
  description = "Security group ID of the Jenkins server"
  value       = aws_security_group.damolak_jenkins_sg.id
}

output "app_sg_id" {
  description = "Security group ID of the application server"
  value       = aws_security_group.damolak_app_sg.id
}

# ── IAM ───────────────────────────────────────────────────────
output "iam_role_arn" {
  description = "ARN of the shared EC2 IAM role"
  value       = aws_iam_role.damolak_ec2_role.arn
}

output "iam_instance_profile_name" {
  description = "Name of the shared EC2 instance profile"
  value       = aws_iam_instance_profile.damolak_ec2_profile.name
}

# ── Backend ───────────────────────────────────────────────────
output "terraform_state_bucket" {
  description = "S3 bucket for Terraform remote state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "terraform_lock_table" {
  description = "DynamoDB table for Terraform state locking"
  value       = aws_dynamodb_table.terraform_lock.name
}