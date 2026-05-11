````md
# Damolak — DevOps Challenge Infrastructure

> **Production-Ready Application Deployment** using Terraform · Docker · Jenkins · AWS EC2 · ECR · S3 · CloudWatch · IAM

This repository provisions the complete AWS infrastructure required to run the Damolak App using **Infrastructure as Code (Terraform)** and integrates with the CI/CD pipeline defined in the **Damalok_App** repository.

> ✅ Project successfully executed, automated, and fully operational

> Production-ready web application source: **Mexant Financial HTML5 Template**

---

# ✅ Brief Steps & Process Used to Achieve This Project

## 1. Designed the Architecture

- Planned a custom VPC in AWS eu-west-1 (Ireland)
- Created public subnet, route table, internet gateway
- Designed two EC2 instances:
  - Jenkins Server
  - Application Server
- Attached Elastic IPs for stable public access
- Planned S3 + DynamoDB backend for Terraform remote state

---

## 2. Provisioned Infrastructure with Terraform

Created modular Terraform files for:

- VPC
- Security Groups
- IAM Roles
- EC2 Instances
- Elastic IPs
- ECR Registry
- CloudWatch Monitoring
- Terraform Backend

Used `user_data` scripts to automatically install:

- Git
- Docker
- Jenkins
- Apache2
- CloudWatch Agent

Bootstrapped and deployed using:

```bash
terraform apply
````

---

## 3. Prepared the Application

* Downloaded ready HTML template
* Customized content and branding
* Created Dockerfile
* Used Nginx to serve the website

---

## 4. Built the CI/CD Pipeline

Created Jenkins pipeline.

### Stages:

```text
Clone → Build → Test → Push to ECR → Deploy
```

---

## 5. Connected Everything

* Jenkins server builds Docker image
* Pushes image to Amazon ECR
* App server pulls latest image
* Runs container
* Apache2 reverse proxies:

```text
Port 80 → Container Port 3000
```

---

## 6. Monitoring & Logging

Configured:

* CloudWatch Log Groups
* CPU Alarms
* Userdata Logs
* Apache Logs
* Jenkins Logs

---

## 7. Documentation & Structure

Organized professionally into two GitHub repositories:

### Infrastructure Repo

`Damalok_Jenkins_Terraform`

### Application Repo

`Damalok_App`

---

# Architecture Overview (eu-west-1 — Ireland)

```text
Damalok VPC (10.0.0.0/16)
└── Public Subnet (10.0.1.0/24)

    ├── Jenkins Server (52.50.38.231)
    │   └── Git + Docker + Jenkins + CloudWatch

    └── App Server (54.77.250.195)
        └── Git + Docker + Apache2 → Docker (:3000)

S3 + DynamoDB → Terraform Remote State
ECR → Docker Images
CloudWatch → Logs & CPU Alarms
```

---

# Architecture Files

Illustrated in:

* `app structural design.pdf`
* `app structural design.mht`

---

# Live URLs & Repositories

| Resource                      | Link                                                 |
| ----------------------------- | ---------------------------------------------------- |
| Jenkins Dashboard             | [http://52.50.38.231:8080](http://52.50.38.231:8080) |
| Live Application              | [http://54.77.250.195](http://54.77.250.195)         |
| Terraform Infrastructure Repo | Damalok_Jenkins_Terraform                            |
| Application Repo              | Damalok_App                                          |

---

# Terraform File Structure

```text
damolak-terraform/
├── main.tf
├── Damolak_variables.tf
├── Damolak_backend.tf
├── Damolak_vpc.tf
├── Damolak_sg.tf
├── Damolak_iam.tf
├── Damolak_jenkens_server.tf
├── Damolak_app_server.tf
├── Damolak_ecr.tf
├── Damolak_cloudwatch.tf
├── Damolak_output.tf
├── terraform.tfvars
├── bootstrap.sh
└── scripts/
```

---

# Tech Stack

| Tool       | Purpose                     |
| ---------- | --------------------------- |
| Terraform  | Infrastructure provisioning |
| AWS EC2    | Jenkins & App servers       |
| AWS ECR    | Docker image registry       |
| AWS S3     | Terraform state storage     |
| DynamoDB   | Terraform locking           |
| CloudWatch | Monitoring & logs           |
| IAM        | Access control              |
| Jenkins    | CI/CD automation            |
| Docker     | Containerization            |
| Nginx      | Web server                  |
| Apache2    | Reverse proxy               |
| GitHub     | Source control              |

---

# Deployment Steps

## Export Credentials

```bash
export TF_VAR_aws_access_key=$Damolak_key
export TF_VAR_aws_secret_key=$Damolak_secret_key
```

## Initialize Backend

```bash
terraform init
terraform apply -target=aws_s3_bucket.terraform_state -target=aws_dynamodb_table.terraform_lock
terraform init -migrate-state
```

## Deploy Infrastructure

```bash
terraform plan -out=damolak.tfplan
terraform apply damolak.tfplan
```

## View Outputs

```bash
terraform output
```

---

# CI/CD Pipeline Stages

| Stage  | Action                          |
| ------ | ------------------------------- |
| Clone  | Pull code from GitHub           |
| Build  | Build Docker image              |
| Test   | Validate container              |
| Push   | Push image to ECR               |
| Deploy | App server pulls and runs image |

---

# Monitoring (CloudWatch)

* Jenkins CPU Alarm
* App CPU Alarm
* Jenkins Logs
* Apache Logs
* userdata Logs

---

# Design Decisions

| Decision             | Reason                      |
| -------------------- | --------------------------- |
| Separate Servers     | Better production structure |
| Elastic IPs          | Stable public access        |
| S3 + DynamoDB        | Safe remote state           |
| Apache Reverse Proxy | Clean exposure              |
| ECR Lifecycle Policy | Cost savings                |

---

# Outcome

This project demonstrates real-world DevOps practices:

* Infrastructure as Code
* CI/CD Automation
* Dockerized Deployment
* AWS Infrastructure
* Monitoring & Logging
* Clean Architecture
* Professional Repository Structure

> ✅ A complete, automated, production-style DevOps environment built from scratch.

```
```
