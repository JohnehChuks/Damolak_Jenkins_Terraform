# =============================================================
# Damolak_jenkens_server.tf — Jenkins CI/CD EC2 Instance
# Project : Damolak DevOps Practical Challenge
# Installs via user_data: Git · Docker CE · Jenkins LTS
# =============================================================

# ── Key Pair — References AWS-created key ─────────────────────
data "aws_key_pair" "damolak_jenkins_keypair" {
  key_name = var.jenkins_keypair_name
}

# ── EC2 Instance ──────────────────────────────────────────────
resource "aws_instance" "damolak_jenkins_server" {
  ami                    = var.ami_id
  instance_type          = var.jenkins_instance_type
  subnet_id              = aws_subnet.damolak_public_subnet.id
  vpc_security_group_ids = [aws_security_group.damolak_jenkins_sg.id]
  key_name               = data.aws_key_pair.damolak_jenkins_keypair.key_name
  iam_instance_profile   = aws_iam_instance_profile.damolak_ec2_profile.name

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.project_name}-jenkins-root-volume"
    }
  }

  user_data = base64encode(templatefile("${path.module}/scripts/jenkins_userdata.sh", {
    jenkins_repo_url = var.jenkins_repo_url
    project_name     = var.project_name
  }))

  depends_on = [
    aws_internet_gateway.damolak_igw,
    aws_iam_instance_profile.damolak_ec2_profile,
  ]

  tags = {
    Name   = var.jenkins_server_name
    Role   = "CI/CD"
    Server = "jenkins"
  }

  lifecycle {
    ignore_changes = [user_data]
  }
}

# ── Elastic IP ────────────────────────────────────────────────
resource "aws_eip" "damolak_jenkins_eip" {
  domain   = "vpc"
  instance = aws_instance.damolak_jenkins_server.id

  depends_on = [aws_internet_gateway.damolak_igw]

  tags = {
    Name   = "${var.project_name}-jenkins-eip"
    Server = "jenkins"
  }
}