#!/bin/bash
# =============================================================
# bootstrap.sh — Complete Damolak Infrastructure Setup
# Run this ONCE to set up everything from scratch
# Usage: chmod +x bootstrap.sh && ./bootstrap.sh
# =============================================================

set -euo pipefail

echo "======================================================="
echo " Damolak Infrastructure Bootstrap"
echo " Timestamp: $(date)"
echo "======================================================="

# ── Check Prerequisites ───────────────────────────────────────
echo "[INFO] Checking prerequisites..."
command -v terraform >/dev/null 2>&1 || { echo "Terraform not installed"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "AWS CLI not installed"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "Git not installed"; exit 1; }

# ── Check AWS Credentials ─────────────────────────────────────
echo "[INFO] Checking AWS credentials..."
if [ -z "${TF_VAR_aws_access_key:-}" ] || [ -z "${TF_VAR_aws_secret_key:-}" ]; then
  echo "[ERROR] AWS credentials not set."
  echo "Run: export TF_VAR_aws_access_key=\$Damolak_key"
  echo "Run: export TF_VAR_aws_secret_key=\$Damolak_secret_key"
  exit 1
fi

# ── Create Keys Directory ─────────────────────────────────────
echo "[INFO] Creating keys directory..."
mkdir -p keys

# ── Generate Jenkins Key ──────────────────────────────────────
echo "[INFO] Setting up Jenkins key pair..."
aws ec2 delete-key-pair \
  --key-name "damolak_jenkins_keypair" \
  --region eu-west-1 2>/dev/null || true

aws ec2 create-key-pair \
  --key-name "damolak_jenkins_keypair" \
  --region eu-west-1 \
  --key-type rsa \
  --key-format pem \
  --query "KeyMaterial" \
  --output text > keys/damolak_jenkins_keypair.pem

chmod 400 keys/damolak_jenkins_keypair.pem
echo "[INFO] Jenkins key created ✅"

# ── Generate App Key ──────────────────────────────────────────
echo "[INFO] Setting up App key pair..."
aws ec2 delete-key-pair \
  --key-name "damolak_app_keypair" \
  --region eu-west-1 2>/dev/null || true

aws ec2 create-key-pair \
  --key-name "damolak_app_keypair" \
  --region eu-west-1 \
  --key-type rsa \
  --key-format pem \
  --query "KeyMaterial" \
  --output text > keys/damolak_app_keypair.pem

chmod 400 keys/damolak_app_keypair.pem
echo "[INFO] App key created ✅"

# ── Terraform Init ────────────────────────────────────────────
echo "[INFO] Initializing Terraform..."
terraform init

# ── Bootstrap S3 Backend ──────────────────────────────────────
echo "[INFO] Creating S3 backend resources..."
terraform apply \
  -target=aws_s3_bucket.terraform_state \
  -target=aws_s3_bucket_versioning.terraform_state \
  -target=aws_s3_bucket_server_side_encryption_configuration.terraform_state \
  -target=aws_s3_bucket_public_access_block.terraform_state \
  -target=aws_dynamodb_table.terraform_lock \
  --auto-approve

# ── Deploy All Infrastructure ─────────────────────────────────
echo "[INFO] Deploying all infrastructure..."
terraform apply --auto-approve

# ── Print Outputs ─────────────────────────────────────────────
echo ""
echo "======================================================="
echo " Damolak Infrastructure — COMPLETE"
echo "======================================================="
terraform output
echo ""
echo " Jenkins URL : $(terraform output -raw jenkins_url)"
echo " App URL     : $(terraform output -raw app_url)"
echo " SSH Jenkins : $(terraform output -raw jenkins_ssh_command)"
echo " SSH App     : $(terraform output -raw app_ssh_command)"
echo "======================================================="