#!/bin/bash
# =============================================================
# bootstrap.sh — Production-Safe Damolak Infrastructure Setup v2
# Safe for first run and repeat runs
# Usage: chmod +x bootstrap.sh && ./bootstrap.sh
# =============================================================

set -euo pipefail

# ── Variables ────────────────────────────────────────────────
AWS_REGION="${AWS_REGION:-eu-west-1}"
KEY_DIR="key"
TF_PLAN_FILE="damolak.tfplan"

# ── Run From Script Directory ────────────────────────────────
cd "$(dirname "$0")"

echo "======================================================="
echo " Damolak Infrastructure Bootstrap v2"
echo " Region    : ${AWS_REGION}"
echo " Timestamp : $(date)"
echo "======================================================="

# ── Check Prerequisites ──────────────────────────────────────
echo "[INFO] Checking prerequisites..."

for cmd in terraform aws git; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "[ERROR] $cmd not installed."
    exit 1
  }
done

# ── Check AWS Credentials ────────────────────────────────────
echo "[INFO] Checking AWS credentials..."

aws sts get-caller-identity >/dev/null 2>&1 || {
  echo "[ERROR] AWS credentials not configured."
  echo "Run: aws configure"
  exit 1
}

# ── Prepare Key Directory ────────────────────────────────────
mkdir -p "${KEY_DIR}"

# ── Function: Ensure Key Pair Exists ─────────────────────────
ensure_keypair () {
  local KEY_NAME="$1"
  local PEM_FILE="$2"

  if [ -f "${PEM_FILE}" ]; then
    echo "[INFO] ${KEY_NAME} private key already exists locally."
    return
  fi

  if aws ec2 describe-key-pairs \
      --key-names "${KEY_NAME}" \
      --region "${AWS_REGION}" >/dev/null 2>&1; then

    echo "[WARN] ${KEY_NAME} exists in AWS but PEM file is missing."
    echo "[WARN] Cannot recover private key from AWS."
    echo "[WARN] Delete key pair manually and rerun if replacement needed."
    return
  fi

  echo "[INFO] Creating ${KEY_NAME}..."

  aws ec2 create-key-pair \
    --key-name "${KEY_NAME}" \
    --region "${AWS_REGION}" \
    --key-type rsa \
    --key-format pem \
    --query KeyMaterial \
    --output text > "${PEM_FILE}"

  chmod 400 "${PEM_FILE}"

  echo "[INFO] ${KEY_NAME} created successfully."
}

# ── Ensure Required Key Pairs ────────────────────────────────
ensure_keypair "damolak_jenkins_keypair" "${KEY_DIR}/damolak_jenkins_keypair.pem"
ensure_keypair "damolak_app_keypair" "${KEY_DIR}/damolak_app_keypair.pem"

# ── Terraform Init ───────────────────────────────────────────
echo "[INFO] Initializing Terraform..."
terraform init

# ── Backend Detection ────────────────────────────────────────
echo "[INFO] Checking Terraform backend..."

if terraform state pull >/dev/null 2>&1; then
  echo "[INFO] Backend already configured."
else
  echo "[INFO] Backend not configured. Bootstrapping backend resources..."

  terraform apply \
    -target=aws_s3_bucket.terraform_state \
    -target=aws_s3_bucket_versioning.terraform_state \
    -target=aws_s3_bucket_server_side_encryption_configuration.terraform_state \
    -target=aws_s3_bucket_public_access_block.terraform_state \
    -target=aws_dynamodb_table.terraform_lock \
    -auto-approve

  terraform init -reconfigure
fi

# ── Terraform Plan ───────────────────────────────────────────
echo "[INFO] Creating Terraform execution plan..."
terraform plan -out="${TF_PLAN_FILE}"

# ── Apply Confirmation ───────────────────────────────────────
echo ""
read -p "Apply Terraform changes now? (yes/no): " CONFIRM

if [ "${CONFIRM}" != "yes" ]; then
  echo "[INFO] Deployment cancelled."
  exit 0
fi

# ── Apply Plan ───────────────────────────────────────────────
echo "[INFO] Applying Terraform plan..."
terraform apply "${TF_PLAN_FILE}"

# ── Final Outputs ────────────────────────────────────────────
echo ""
echo "======================================================="
echo " Damolak Infrastructure — COMPLETE"
echo "======================================================="

terraform output || true

echo ""
echo " Jenkins URL : $(terraform output -raw jenkins_url 2>/dev/null || echo N/A)"
echo " App URL     : $(terraform output -raw app_url 2>/dev/null || echo N/A)"
echo ""
echo " Jenkins IP  : $(terraform output -raw jenkins_server_public_ip 2>/dev/null || echo N/A)"
echo " App IP      : $(terraform output -raw app_server_public_ip 2>/dev/null || echo N/A)"
echo "======================================================="