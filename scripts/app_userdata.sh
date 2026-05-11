#!/bin/bash
# =============================================================
# scripts/app_userdata.sh
# Bootstrap: Git + Docker CE + Apache2 + CloudWatch Agent
# OS       : Ubuntu 24.04 LTS
#
# Templated by Terraform templatefile():
#   ${app_repo_url}
#   ${project_name}
# =============================================================

set -euo pipefail

exec > >(tee /var/log/damolak-app-userdata.log | logger -t userdata -s 2>/dev/console) 2>&1

echo "======================================================="
echo " Damolak App Server — Bootstrap Start"
echo " Timestamp: $(date)"
echo "======================================================="

# ── Wait For Apt Lock ────────────────────────────────────────
echo "[INFO] Waiting for apt lock..."
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  sleep 10
done

# ── System Update ────────────────────────────────────────────
echo "[INFO] Updating system..."
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

apt-get install -y \
  curl wget unzip gnupg \
  lsb-release software-properties-common \
  apt-transport-https ca-certificates \
  git apache2

# ── Docker Install ───────────────────────────────────────────
echo "[INFO] Installing Docker..."

install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
| gpg --dearmor -o /etc/apt/keyrings/docker.gpg

chmod a+r /etc/apt/keyrings/docker.gpg

UBUNTU_CODENAME=$(lsb_release -cs || echo noble)

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$${UBUNTU_CODENAME} stable" \
| tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y

apt-get install -y \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu || true

docker --version

# ── Apache Reverse Proxy ─────────────────────────────────────
echo "[INFO] Configuring Apache..."

a2enmod proxy proxy_http headers rewrite

cat > /etc/apache2/sites-available/${project_name}-app.conf <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost

    ProxyPreserveHost On
    ProxyPass / http://localhost:3000/
    ProxyPassReverse / http://localhost:3000/

    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"

    ErrorLog \$${APACHE_LOG_DIR}/damolak-app-error.log
    CustomLog \$${APACHE_LOG_DIR}/damolak-app-access.log combined
</VirtualHost>
EOF

a2dissite 000-default.conf || true
a2ensite ${project_name}-app.conf

apache2ctl configtest
systemctl enable apache2
systemctl restart apache2

# ── Clone App Repo (Rerunnable) ──────────────────────────────
echo "[INFO] Preparing app repo..."

mkdir -p /opt/${project_name}

if [ ! -d /opt/${project_name}/app-terraform/.git ]; then
  git clone ${app_repo_url} /opt/${project_name}/app-terraform
else
  cd /opt/${project_name}/app-terraform
  git pull
fi

# ── CloudWatch Agent ─────────────────────────────────────────
echo "[INFO] Installing CloudWatch Agent..."

wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb \
-O /tmp/amazon-cloudwatch-agent.deb

dpkg -i /tmp/amazon-cloudwatch-agent.deb || apt-get install -f -y

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/apache2/damolak-app-access.log",
            "log_group_name": "/damolak/app/apache-access",
            "log_stream_name": "{instance_id}/apache-access"
          },
          {
            "file_path": "/var/log/apache2/damolak-app-error.log",
            "log_group_name": "/damolak/app/apache-error",
            "log_stream_name": "{instance_id}/apache-error"
          },
          {
            "file_path": "/var/log/damolak-app-userdata.log",
            "log_group_name": "/damolak/app/userdata",
            "log_stream_name": "{instance_id}/userdata"
          }
        ]
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config \
-m ec2 \
-c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
-s

systemctl enable amazon-cloudwatch-agent

# ── Health Checks ────────────────────────────────────────────
echo "[INFO] Running service checks..."

systemctl is-active --quiet docker
systemctl is-active --quiet apache2
systemctl is-active --quiet amazon-cloudwatch-agent

# ── Get Public IP (IMDSv2) ───────────────────────────────────
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
-H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)

PUBLIC_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
-s http://169.254.169.254/latest/meta-data/public-ipv4)

# ── Final Output ─────────────────────────────────────────────
echo "======================================================="
echo " Damolak App Server — Bootstrap Complete"
echo " App URL   : http://$${PUBLIC_IP}"
echo " Timestamp : $(date)"
echo "======================================================="