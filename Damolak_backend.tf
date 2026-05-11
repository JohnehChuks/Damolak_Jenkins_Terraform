# =============================================================
# Damolak_backend.tf — Remote State Bootstrap Resources
# Project : Damolak DevOps Practical Challenge
#
# Creates:
#   - S3 bucket for Terraform remote state
#   - DynamoDB lock table
#   - Versioning + Encryption + Public Access Block
#   - Lifecycle cleanup for old state versions
# =============================================================

# =============================================================
# S3 BUCKET — TERRAFORM STATE
# =============================================================
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "${var.project_name}-terraform-state"
  force_destroy = false

  tags = {
    Name        = "${var.project_name}-terraform-state"
    Environment = var.environment
  }
}

# =============================================================
# VERSIONING
# =============================================================
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# =============================================================
# SERVER SIDE ENCRYPTION
# =============================================================
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# =============================================================
# BLOCK PUBLIC ACCESS
# =============================================================
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# =============================================================
# LIFECYCLE POLICY — CLEAN OLD STATE VERSIONS
# =============================================================
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# =============================================================
# DYNAMODB TABLE — STATE LOCKING
# =============================================================
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "${var.project_name}-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-terraform-lock"
    Environment = var.environment
  }
}