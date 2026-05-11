#!/bin/bash
# =============================================================
# scripts/jenkins_userdata.sh
# Bootstrap: Git + Docker CE + Jenkins LTS + CloudWatch Agent
# OS       : Ubuntu 24.04 LTS
# Java     : OpenJDK 21
#
# Templated by Terraform templatefile():
#   ${jenkins_repo_url}
#   ${project_name}
# =============================================================

set -euo pipefail
exec > >(tee /var/log/damolak-jenkins-userdata.log | logger -t userdata -s 2>/dev/console) 2>&1

echo "======================================================="
echo " Damolak Jenkins Server — Bootstrap Start"
echo " Timestamp : $(date)"
echo "======================================================="

# ── 1. Wait for apt lock ──────────────────────────────────────
echo "[INFO] Waiting for apt lock..."
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  sleep 10
done

# ── 2. System Updates ────────────────────────────────────────
echo "[INFO] Updating packages..."
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

apt-get install -y \
  curl wget unzip git gnupg \
  lsb-release software-properties-common \
  apt-transport-https ca-certificates jq

# ── 3. Install Docker CE ─────────────────────────────────────
echo "[INFO] Installing Docker..."

install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
| gpg --dearmor -o /etc/apt/keyrings/docker.gpg

chmod a+r /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" \
| tee /etc/apt/sources.list.d/docker.list >/dev/null

apt-get update -y

apt-get install -y \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl restart docker

usermod -aG docker ubuntu || true

# ── 4. Install Java 21 ───────────────────────────────────────
echo "[INFO] Installing OpenJDK 21..."
apt-get install -y openjdk-21-jre

update-alternatives --set java \
/usr/lib/jvm/java-21-openjdk-amd64/bin/java || true

java -version

# ── 5. Install Jenkins LTS ───────────────────────────────────
echo "[INFO] Installing Jenkins..."

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
| tee /usr/share/keyrings/jenkins-keyring.asc >/dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" \
| tee /etc/apt/sources.list.d/jenkins.list >/dev/null

apt-get update -y
apt-get install -y jenkins

usermod -aG docker jenkins || true

systemctl enable jenkins
systemctl restart jenkins

# ── 6. Wait for Jenkins ──────────────────────────────────────
echo "[INFO] Waiting for Jenkins startup..."
sleep 45

# ── 7. Copy App Private Key to Jenkins ───────────────────────
echo "[INFO] Preparing Jenkins SSH deploy key..."

if [ -f /home/ubuntu/key/damolak_app_keypair.pem ]; then
  cp /home/ubuntu/key/damolak_app_keypair.pem /var/lib/jenkins/
  chown jenkins:jenkins /var/lib/jenkins/damolak_app_keypair.pem
  chmod 400 /var/lib/jenkins/damolak_app_keypair.pem
fi

# ── 8. Clone Jenkins Repo ────────────────────────────────────
echo "[INFO] Cloning project repository..."

mkdir -p /opt/${project_name}

git clone ${jenkins_repo_url} \
/opt/${project_name}/jenkins-terraform \
|| echo "[WARN] Clone failed."

# ── 9. Install CloudWatch Agent ──────────────────────────────
echo "[INFO] Installing CloudWatch Agent..."

wget -q \
https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb \
-O /tmp/amazon-cloudwatch-agent.deb

dpkg -i /tmp/amazon-cloudwatch-agent.deb || apt-get install -f -y

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWCONFIG'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/jenkins/jenkins.log",
            "log_group_name": "/damolak/jenkins/application",
            "log_stream_name": "{instance_id}/jenkins"
          },
          {
            "file_path": "/var/log/damolak-jenkins-userdata.log",
            "log_group_name": "/damolak/jenkins/userdata",
            "log_stream_name": "{instance_id}/userdata"
          }
        ]
      }
    }
  }
}
CWCONFIG

systemctl enable amazon-cloudwatch-agent
systemctl restart amazon-cloudwatch-agent

# ── 10. Show Jenkins Password ────────────────────────────────
echo "[INFO] Jenkins Admin Password:"
cat /var/lib/jenkins/secrets/initialAdminPassword || true

# ── 11. Final Output ─────────────────────────────────────────
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "SERVER_IP")

echo "======================================================="
echo " Damolak Jenkins Server — Bootstrap Complete"
echo " Jenkins URL : http://$${PUBLIC_IP}:8080"
echo " Timestamp   : $(date)"
echo "======================================================="