# =============================================================
# main.tf — Root Entry Point
# Project : Damolak DevOps Challenge
# Author  : John sunday Chukwu
# Region  : eu-west-1 (Ireland)
# =============================================================

terraform {
  required_version = ">= 1.5.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "damolak-jc-terraform-state"
    key            = "damolak/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "damolak-jc-terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "Damolak"
    }
  }
}