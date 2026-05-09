#!/bin/bash
# =============================================================
# scripts/app_userdata.sh
# Bootstrap: Git + Docker CE + Apache2 (reverse proxy)
# OS      : Debian 12 (Bookworm)
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

# ── 1. Wait for apt lock ──────────────────────────────────────
echo "[INFO] Waiting for apt lock..."
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  echo "[INFO] Waiting for apt lock to be released..."
  sleep 10
done

# ── 2. System Updates ────────────────────────────────────────
echo "[INFO] Updating system..."
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
apt-get install -y \
  curl wget unzip gnupg \
  lsb-release software-properties-common \
  apt-transport-https ca-certificates

# ── 3. Git ───────────────────────────────────────────────────
echo "[INFO] Installing Git..."
apt-get install -y git
git --version

# ── 4. Docker CE ─────────────────────────────────────────────
echo "[INFO] Installing Docker CE..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl start docker
usermod -aG docker admin
docker --version

# ── 5. Apache2 ───────────────────────────────────────────────
echo "[INFO] Installing Apache2..."
apt-get install -y apache2

a2enmod proxy proxy_http headers rewrite

cat > /etc/apache2/sites-available/${project_name}-app.conf <<'APACHECONF'
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    ProxyPreserveHost On
    ProxyPass        / http://localhost:3000/
    ProxyPassReverse / http://localhost:3000/

    Header always set X-Content-Type-Options  "nosniff"
    Header always set X-Frame-Options         "SAMEORIGIN"
    Header always set X-XSS-Protection        "1; mode=block"
    Header always set Referrer-Policy         "strict-origin-when-cross-origin"

    ErrorLog  $${APACHE_LOG_DIR}/damolak-app-error.log
    CustomLog $${APACHE_LOG_DIR}/damolak-app-access.log combined
</VirtualHost>
APACHECONF

a2dissite 000-default.conf
a2ensite ${project_name}-app.conf
apache2ctl configtest

systemctl enable apache2
systemctl restart apache2

# ── 6. Clone App Repo ─────────────────────────────────────────
echo "[INFO] Cloning App repo..."
mkdir -p /opt/${project_name}
git clone ${app_repo_url} /opt/${project_name}/app-terraform \
  || echo "[WARN] Clone failed — check repo access."

# ── 7. CloudWatch Agent ───────────────────────────────────────
echo "[INFO] Installing CloudWatch Agent..."
wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb \
  -O /tmp/amazon-cloudwatch-agent.deb
dpkg -i /tmp/amazon-cloudwatch-agent.deb

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWCONFIG'
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
CWCONFIG

systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

echo "======================================================="
echo " Damolak App Server — Bootstrap Complete"
echo " App URL   : http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo " Timestamp : $(date)"
echo "======================================================="