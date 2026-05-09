#!/bin/bash
# =============================================================
# scripts/jenkins_userdata.sh
# Bootstrap: Git + Docker CE + Jenkins LTS + CloudWatch Agent
# OS      : Debian 12 (Bookworm)
# Java    : OpenJDK 21 (Jenkins 2.555+ requires Java 21)
#
# Templated by Terraform templatefile():
#   ${jenkins_repo_url}
#   ${project_name}
# =============================================================

set -euo pipefail
exec > >(tee /var/log/damolak-jenkins-userdata.log | logger -t userdata -s 2>/dev/console) 2>&1

echo "======================================================="
echo " Damolak Jenkins Server — Bootstrap Start"
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

# ── 5. Java 21 ───────────────────────────────────────────────
echo "[INFO] Installing Java 21..."
apt-get install -y openjdk-21-jre
update-alternatives --set java \
  /usr/lib/jvm/java-21-openjdk-amd64/bin/java
java -version

# ── 6. Jenkins LTS ───────────────────────────────────────────
echo "[INFO] Installing Jenkins..."

apt-key adv \
  --keyserver keyserver.ubuntu.com \
  --recv-keys 7198F4B714ABFC68

echo "deb https://pkg.jenkins.io/debian-stable binary/" \
  | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

apt-get update -y
apt-get install -y jenkins

usermod -aG docker jenkins
systemctl enable jenkins
systemctl start jenkins

echo "[INFO] Waiting for Jenkins to start..."
sleep 60

echo "[INFO] Jenkins initial admin password:"
cat /var/lib/jenkins/secrets/initialAdminPassword \
  || echo "[WARN] Password not yet available"

# ── 7. Clone Jenkins Repo ─────────────────────────────────────
echo "[INFO] Cloning Jenkins Terraform repo..."
mkdir -p /opt/${project_name}
git clone ${jenkins_repo_url} /opt/${project_name}/jenkins-terraform \
  || echo "[WARN] Clone failed — check repo access."

# ── 8. CloudWatch Agent ───────────────────────────────────────
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
systemctl start amazon-cloudwatch-agent

echo "======================================================="
echo " Damolak Jenkins Server — Bootstrap Complete"
echo " Jenkins URL : http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo " Timestamp   : $(date)"
echo "======================================================="