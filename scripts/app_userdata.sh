#!/bin/bash
# =============================================================
# scripts/app_userdata.sh
# Bootstrap: Git + Docker CE + Apache2 (reverse proxy) + CloudWatch
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

# ── 1. System Updates ────────────────────────────────────────
apt-get update -y
apt-get upgrade -y
apt-get install -y \
  curl wget unzip ca-certificates gnupg \
  lsb-release software-properties-common apt-transport-https

# ── 2. Git ───────────────────────────────────────────────────
echo "[INFO] Installing Git..."
apt-get install -y git
git --version

# ── 3. Docker CE ─────────────────────────────────────────────
echo "[INFO] Installing Docker CE..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu
docker --version

# ── 4. Apache2 — Install & Configure ─────────────────────────
echo "[INFO] Installing Apache2..."
apt-get install -y apache2

a2enmod proxy
a2enmod proxy_http
a2enmod headers
a2enmod rewrite

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

# ── 5. Clone App Terraform Repo ───────────────────────────────
echo "[INFO] Cloning App Terraform repo..."
mkdir -p /opt/${project_name}
git clone ${app_repo_url} /opt/${project_name}/app-terraform \
  || echo "[WARN] Clone failed — check repo access."

# ── 6. CloudWatch Agent ───────────────────────────────────────
echo "[INFO] Installing CloudWatch Agent..."
wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb \
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