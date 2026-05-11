# =============================================================
# Damolak_variables.tf — All Input Variable Declarations
# Project : Damolak DevOps Practical Challenge
# =============================================================

# =============================================================
# PROVIDER / AUTH
# =============================================================

variable "aws_access_key" {
  description = "AWS Access Key ID (optional if using aws configure / IAM role)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Access Key (optional if using aws configure / IAM role)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-west-1"
}

# =============================================================
# PROJECT META
# =============================================================

variable "project_name" {
  description = "Short project identifier used in names and tags"
  type        = string
  default     = "damolak-jc"
}

variable "environment" {
  description = "Deployment environment (dev | staging | prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# =============================================================
# ALERTING
# =============================================================

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = "your-email@example.com"
}

# =============================================================
# NETWORKING
# =============================================================

variable "vpc_cidr" {
  description = "CIDR block for the shared VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for EC2 subnet"
  type        = string
  default     = "eu-west-1a"
}

# =============================================================
# PRIVATE IPS
# =============================================================

variable "jenkins_private_ip" {
  description = "Fixed private IP for Jenkins server"
  type        = string
  default     = "10.0.1.10"
}

variable "app_private_ip" {
  description = "Fixed private IP for App server"
  type        = string
  default     = "10.0.1.100"
}

# =============================================================
# EC2 — JENKINS
# =============================================================

variable "jenkins_instance_type" {
  description = "EC2 instance type for Jenkins server"
  type        = string
  default     = "t3.micro"
}

variable "jenkins_server_name" {
  description = "Name tag for Jenkins EC2 instance"
  type        = string
  default     = "damolak-jenkins-server"
}

variable "jenkins_keypair_name" {
  description = "AWS key pair name for Jenkins server"
  type        = string
  default     = "damolak_jenkins_keypair"
}

# =============================================================
# EC2 — APP SERVER
# =============================================================

variable "app_instance_type" {
  description = "EC2 instance type for App server"
  type        = string
  default     = "t3.micro"
}

variable "app_server_name" {
  description = "Name tag for App EC2 instance"
  type        = string
  default     = "damolak-app-server"
}

variable "app_keypair_name" {
  description = "AWS key pair name for App server"
  type        = string
  default     = "damolak_app_keypair"
}

# =============================================================
# AMI
# =============================================================

variable "ami_id" {
  description = "Ubuntu 24.04 LTS AMI for eu-west-1"
  type        = string
  default     = "ami-0d64bb532e0502c46"
}

# =============================================================
# IAM
# =============================================================

variable "iam_role_name" {
  description = "IAM role shared by both EC2 instances"
  type        = string
  default     = "damolak-ec2-role"
}

# =============================================================
# GITHUB REPOSITORIES
# =============================================================

variable "jenkins_repo_url" {
  description = "GitHub repo URL for Jenkins server provisioning"
  type        = string
  default     = "https://github.com/JohnehChuks/Damolak_Jenkins_Terraform.git"
}

variable "app_repo_url" {
  description = "GitHub repo URL for App server provisioning"
  type        = string
  default     = "https://github.com/JohnehChuks/Damolak_App.git"
}