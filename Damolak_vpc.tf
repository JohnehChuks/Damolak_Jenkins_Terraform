# =============================================================
# Damolak_vpc.tf — Shared VPC, Subnets & Routing
# Project : Damolak DevOps Practical Challenge
# Both servers share this VPC and public subnet.
# =============================================================

resource "aws_vpc" "damolak_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "damolak_igw" {
  vpc_id = aws_vpc.damolak_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "damolak_public_subnet" {
  vpc_id                  = aws_vpc.damolak_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
    Tier = "Public"
  }
}

resource "aws_route_table" "damolak_public_rt" {
  vpc_id = aws_vpc.damolak_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.damolak_igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "damolak_public_rta" {
  subnet_id      = aws_subnet.damolak_public_subnet.id
  route_table_id = aws_route_table.damolak_public_rt.id
}