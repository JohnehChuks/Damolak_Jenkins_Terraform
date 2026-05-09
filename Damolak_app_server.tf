# =============================================================
# Damolak_app_server.tf — Application EC2 Instance
# Project : Damolak DevOps Practical Challenge
# Installs via user_data: Git · Docker CE · Apache2
# =============================================================

# ── Key Pair ──────────────────────────────────────────────────
resource "aws_key_pair" "damolak_app_keypair" {
  key_name   = var.app_keypair_name
  public_key = file("${path.module}/keys/damolak_app_keypair.pem.pub")

  tags = {
    Name   = var.app_keypair_name
    Server = "app"
  }
}

# ── EC2 Instance ──────────────────────────────────────────────
resource "aws_instance" "damolak_app_server" {
  ami                    = var.ami_id
  instance_type          = var.app_instance_type
  subnet_id              = aws_subnet.damolak_public_subnet.id
  vpc_security_group_ids = [aws_security_group.damolak_app_sg.id]
  key_name               = aws_key_pair.damolak_app_keypair.key_name
  iam_instance_profile   = aws_iam_instance_profile.damolak_ec2_profile.name

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.project_name}-app-root-volume"
    }
  }

  user_data = base64encode(templatefile("${path.module}/scripts/app_userdata.sh", {
    app_repo_url = var.app_repo_url
    project_name = var.project_name
  }))

  depends_on = [
    aws_internet_gateway.damolak_igw,
    aws_iam_instance_profile.damolak_ec2_profile,
  ]

  tags = {
    Name   = var.app_server_name
    Role   = "Application"
    Server = "app"
  }

  lifecycle {
    ignore_changes = [user_data]
  }
}

# ── Elastic IP ────────────────────────────────────────────────
resource "aws_eip" "damolak_app_eip" {
  domain   = "vpc"
  instance = aws_instance.damolak_app_server.id

  depends_on = [aws_internet_gateway.damolak_igw]

  tags = {
    Name   = "${var.project_name}-app-eip"
    Server = "app"
  }
}