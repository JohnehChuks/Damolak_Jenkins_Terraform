# =============================================================
# Damolak_variables.tf — All Input Variable Declarations
# Project : Damolak DevOps Practical Challenge
# =============================================================

# ── Provider / Auth ───────────────────────────────────────────
variable "aws_access_key" {
  description = "AWS Access Key ID (exported as Damolak_key)"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Access Key (exported as Damolak_secret_key)"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-west-1"
}

# ── Project Meta ──────────────────────────────────────────────
variable "project_name" {
  description = "Short project identifier used in resource names and tags"
  type        = string
  default     = "damolak"
}

variable "environment" {
  description = "Deployment environment (dev | staging | prod)"
  type        = string
  default     = "dev"
}

# ── VPC ───────────────────────────────────────────────────────
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
  description = "Availability zone for the subnets"
  type        = string
  default     = "eu-west-1a"
}

# ── EC2 — Jenkins ─────────────────────────────────────────────
variable "jenkins_instance_type" {
  description = "EC2 instance type for Jenkins server"
  type        = string
  default     = "t3.micro"
}

# ── EC2 — App Server ─────────────────────────────────────────
variable "app_instance_type" {
  description = "EC2 instance type for App server"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "Debian 12 (Bookworm) AMI for eu-west-1"
  type        = string
  default     = "ami-0eb11ab33f229b26c"
}

# ── EC2 — Jenkins ─────────────────────────────────────────────
variable "jenkins_server_name" {
  description = "Name tag for the Jenkins EC2 instance"
  type        = string
  default     = "damolak-jenkins-server"
}

variable "jenkins_keypair_name" {
  description = "AWS key pair name for the Jenkins server"
  type        = string
  default     = "damolak_jenkins_keypair"
}

# ── EC2 — App Server ─────────────────────────────────────────
variable "app_server_name" {
  description = "Name tag for the application EC2 instance"
  type        = string
  default     = "damolak-app-server"
}

variable "app_keypair_name" {
  description = "AWS key pair name for the App server"
  type        = string
  default     = "damolak_app_keypair"
}

# ── IAM ───────────────────────────────────────────────────────
variable "iam_role_name" {
  description = "IAM role name shared by both EC2 instances"
  type        = string
  default     = "damolak-ec2-role"
}

# ── GitHub Repos ─────────────────────────────────────────────
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