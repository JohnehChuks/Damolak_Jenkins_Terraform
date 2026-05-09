# Damolak — DevOps Challenge Infrastructure

> **Production-Ready Application Deployment** | Terraform · AWS EC2 · Jenkins · Docker · Apache2 · ECR · CloudWatch

---

## Architecture Overview
eu-west-1 (Ireland)
┌─────────────────────────────────────────────────────────────┐
│  Damolak VPC  (10.0.0.0/16)                                 │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Public Subnet  (10.0.1.0/24) — eu-west-1a             │ │
│  │                                                        │ │
│  │  ┌──────────────────────┐  ┌──────────────────────┐   │ │
│  │  │  Jenkins Server      │  │  App Server           │   │ │
│  │  │  t3.micro            │  │  t2.micro             │   │ │
│  │  │  EIP: 52.50.38.231   │  │  EIP: 54.77.250.195   │   │ │
│  │  │  SG: jenkins-sg      │  │  SG: app-sg           │   │ │
│  │  │  Ports: 22,80,443,   │  │  Ports: 22,80,443     │   │ │
│  │  │         8080         │  │  Apache2 → :3000      │   │ │
│  │  │  Git+Docker+Jenkins  │  │  Git+Docker+Apache2   │   │ │
│  │  └──────────────────────┘  └──────────────────────┘   │ │
│  └────────────────────────────────────────────────────────┘ │
│  IGW ──── Route Table (0.0.0.0/0 → IGW)                     │
└─────────────────────────────────────────────────────────────┘
│                              │
Elastic IP                     Elastic IP
(Jenkins EIP)                   (App EIP)
Remote State : S3 (damolak-jc-terraform-state) + DynamoDB (damolak-jc-terraform-lock)
IAM          : Shared EC2 role → ECR + S3 (read) + CloudWatch + SSM
ECR          : 832599277470.dkr.ecr.eu-west-1.amazonaws.com/damolak-jc-app
CloudWatch   : Log groups + CPU alarms for both servers
---

## File Structure
damolak-terraform/
├── main.tf                        # Provider, Terraform version, S3 backend
├── Damolak_variables.tf           # All variable declarations
├── Damolak_backend.tf             # S3 bucket + DynamoDB lock table
├── Damolak_vpc.tf                 # VPC, IGW, public subnet, route table
├── Damolak_sg.tf                  # Jenkins SG + App SG
├── Damolak_iam.tf                 # IAM role, policy, instance profile
├── Damolak_jenkens_server.tf      # Jenkins EC2, key pair, Elastic IP
├── Damolak_app_server.tf          # App EC2, key pair, Elastic IP
├── Damolak_ecr.tf                 # ECR repository + lifecycle policy
├── Damolak_cloudwatch.tf          # CloudWatch log groups + CPU alarms
├── Damolak_output.tf              # All output values
├── terraform.tfvars               # Variable values
├── bootstrap.sh                   # One-command full setup script
├── .gitignore                     # Excludes state, keys, tfvars
├── keys/                          # Auto-generated .pem files (git-ignored)
│   ├── damolak_jenkins_keypair.pem
│   └── damolak_app_keypair.pem
└── scripts/
├── jenkins_userdata.sh        # Bootstrap: Git + Docker + Jenkins + CW Agent
└── app_userdata.sh            # Bootstrap: Git + Docker + Apache2 + CW Agent
---

## Tech Stack

| Tool | Purpose |
|---|---|
| Terraform | Infrastructure provisioning |
| AWS EC2 | Cloud servers (Debian 12) |
| AWS ECR | Docker image registry |
| AWS S3 + DynamoDB | Terraform remote state + locking |
| AWS CloudWatch | Monitoring, logging and CPU alarms |
| AWS IAM | Role-based access control |
| Jenkins | CI/CD pipeline |
| Docker | Containerization |
| Nginx | Web server inside container |
| Apache2 | Reverse proxy on App server |
| Git | Version control |

---

## Prerequisites

| Tool | Version |
|---|---|
| Terraform | >= 1.5.2 |
| AWS CLI | v2.x |
| Git | any |

---

## Quick Start — One Command Setup

```bash
# 1. Clone the repo
git clone https://github.com/JohnehChuks/Damolak_Jenkins_Terraform.git
cd Damolak_Jenkins_Terraform

# 2. Export AWS credentials
export TF_VAR_aws_access_key=$Damolak_key
export TF_VAR_aws_secret_key=$Damolak_secret_key

# 3. Run bootstrap script
chmod +x bootstrap.sh
./bootstrap.sh
```

---

## Manual Deployment Steps

### Step 1 — Export Credentials
```bash
export TF_VAR_aws_access_key=$Damolak_key
export TF_VAR_aws_secret_key=$Damolak_secret_key
```

### Step 2 — Bootstrap Remote State (first time only)
```bash
terraform init
terraform apply \
  -target=aws_s3_bucket.terraform_state \
  -target=aws_dynamodb_table.terraform_lock
terraform init -migrate-state
```

### Step 3 — Deploy Everything
```bash
terraform plan -out=damolak.tfplan
terraform apply damolak.tfplan
```

### Step 4 — Access Servers
```bash
terraform output jenkins_url
terraform output app_url
terraform output jenkins_ssh_command
terraform output app_ssh_command
```

### Step 5 — Destroy When Done
```bash
terraform destroy
```

---

## CI/CD Pipeline Stages

| Stage | What Happens |
|---|---|
| Clone | Pulls latest code from GitHub developer branch |
| Build | Builds Docker image from Dockerfile |
| Test | Runs container and tests with curl |
| Deploy | Copies image to App server and runs container |

---

## Monitoring

| Resource | Details |
|---|---|
| Jenkins CPU Alarm | Triggers when CPU > 80% for 4 minutes |
| App CPU Alarm | Triggers when CPU > 80% for 4 minutes |
| Jenkins Log Group | `/damolak/jenkins/application` |
| Jenkins UserData Log | `/damolak/jenkins/userdata` |
| App Apache Access Log | `/damolak/app/apache-access` |
| App Apache Error Log | `/damolak/app/apache-error` |
| App UserData Log | `/damolak/app/userdata` |

---

## Design Decisions

| Decision | Rationale |
|---|---|
| Debian 12 AMI | Available AMI in eu-west-1 — scripts updated for Debian |
| Single public subnet | Simplicity for challenge scope |
| Shared IAM role | Both servers need ECR + CloudWatch — DRY principle |
| Separate security groups | Jenkins needs port 8080; App does not |
| Elastic IPs | Prevents IP change on instance stop/start |
| gp3 EBS | Better baseline performance at no extra cost vs gp2 |
| Apache2 reverse proxy | Decouples web layer from Docker container port |
| S3 + DynamoDB backend | Team-safe state locking with audit trail |
| AWS-generated key pairs | Most reliable method — no key format mismatch |
| ECR lifecycle policy | Keeps only last 5 images to save storage costs |

---

## Assumptions

- AWS credentials exported as environment variables
- Both servers in eu-west-1 (Ireland) region
- Debian 12 (Bookworm) AMI used for both servers
- Jenkins and App server share same VPC and public subnet
- GitHub repos are public and accessible

---

## Limitations and Future Improvements

### Security
- Move App server to **private subnet** behind a Load Balancer
- Add **HTTPS/TLS** using AWS Certificate Manager
- Restrict SSH access to specific IP ranges only
- Enable **AWS GuardDuty** for threat detection
- Add **AWS WAF** for web application firewall protection

### High Availability
- Add **Auto Scaling Group** for App server
- Add **Application Load Balancer** for traffic distribution
- Deploy across **multiple availability zones**
- Add **RDS** for persistent database storage

### CI/CD Improvements
- Push Docker images to **ECR** and pull on App server
- Add **automated rollback** on deployment failure
- Add **Slack notifications** for pipeline status
- Implement **Blue/Green deployment** strategy
- Add **SonarQube** for code quality scanning

### Monitoring
- Add **AWS SNS** for alarm notifications via email/SMS
- Implement **custom CloudWatch dashboards**
- Add **application-level metrics** using CloudWatch EMF
- Set up **AWS X-Ray** for distributed tracing

### Infrastructure
- Use **Terraform modules** for better reusability
- Add **fixed private IPs** to prevent Jenkinsfile updates on recreation
- Implement **VPC endpoints** for private AWS service access
- Add **NAT Gateway** for private subnet internet access