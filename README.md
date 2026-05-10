**[Damalok_Jenkins_Terraform](https://github.com/JohnehChuks/Damolak_Jenkins_Terraform?utm_source=chatgpt.com)**.

## ✅ Brief Steps & Process Used to Achieve This Project

1. **Designed the Architecture**

   * Planned a VPC, public subnet, security groups, IAM roles, and two EC2 servers (Jenkins & App) in **Amazon Web Services** eu-west-1.
   * Assigned Elastic IPs for stable access.
   * Planned S3 + DynamoDB for Terraform remote state.

2. **Provisioned Infrastructure with Terraform**

   * Wrote modular Terraform files to create VPC, SG, IAM, EC2, ECR, CloudWatch.
   * Used `user_data` scripts to automatically install Git, Docker, Jenkins, Apache2, and CloudWatch agent.
   * Bootstrapped remote state and deployed with `terraform apply`.

3. **Prepared the Application**

   * Downloaded a ready HTML template and made slight edits.
   * Created a **Dockerfile** to serve the app using Nginx.

4. **Built the CI/CD Pipeline**

   * Wrote a **Jenkinsfile**.
   * Pipeline stages: Clone → Build Docker image → Test → Push to ECR → Deploy on App server.

5. **Connected Everything**

   * Jenkins server builds and pushes image to ECR.
   * App server pulls image and runs container.
   * Apache2 reverse proxies port 80 to container port 3000.

6. **Monitoring & Logging**

   * Configured CloudWatch log groups and CPU alarms for both servers.

7. **Documentation & Structure**

   * Organized into two professional GitHub repositories:

     * Infrastructure repo
     * Application repo

---

# ✅ COMPLETE README.md FILE


---

# Damolak — DevOps Challenge Infrastructure

> **Production-Ready Application Deployment** using Terraform · Docker · Jenkins · AWS EC2 · ECR · S3 · CloudWatch · IAM

This repository provisions the complete AWS infrastructure required to run the Damolak App using **Infrastructure as Code (Terraform)** and integrates with the CI/CD pipeline defined in the **[Damalok_App](https://github.com/JohnehChuks/Damolak_App?utm_source=chatgpt.com)** repository.

> ✅ Project successfully executed, automated, and fully operational

---
**Production-ready web App source:** Mexant Financial HTML5 template.

## Architecture Overview (eu-west-1 — Ireland)

```
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

Architecture and Terraform structures are illustrated in:

* `assets/damalok_architecture.png`
* `assets/damalok_structures.png`

---

## Live URLs & Repositories

| Resource                      | Link                                                                                                         |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------ |
| Jenkins Dashboard             | [http://52.50.38.231:8080](http://52.50.38.231:8080)                                                         |
| Live Application              | [http://54.77.250.195](http://54.77.250.195)                                                                 |
| Terraform Infrastructure Repo | [Damalok_Jenkins_Terraform](https://github.com/JohnehChuks/Damolak_Jenkins_Terraform?utm_source=chatgpt.com) |
| Application & CI/CD Repo      | [Damalok_App](https://github.com/JohnehChuks/Damolak_App?utm_source=chatgpt.com)                             |

---

## Terraform File Structure

```
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

## Tech Stack

| Tool              | Purpose                     |
| ----------------- | --------------------------- |
| Terraform         | Infrastructure provisioning |
| AWS EC2           | Jenkins and App servers     |
| AWS ECR           | Docker image registry       |
| AWS S3 + DynamoDB | Remote state & locking      |
| AWS CloudWatch    | Monitoring and logging      |
| AWS IAM           | Access control              |
| Jenkins           | CI/CD automation            |
| Docker            | Containerization            |
| Nginx             | Web server in container     |
| Apache2           | Reverse proxy               |
| Git & GitHub      | Version control             |

---

## Deployment Steps

### Export Credentials

```bash
export TF_VAR_aws_access_key=$Damolak_key
export TF_VAR_aws_secret_key=$Damolak_secret_key
```

### Initialize & Bootstrap State

```bash
terraform init
terraform apply -target=aws_s3_bucket.terraform_state -target=aws_dynamodb_table.terraform_lock
terraform init -migrate-state
```

### Deploy Infrastructure

```bash
terraform plan -out=damolak.tfplan
terraform apply damolak.tfplan
```

### Access Outputs

```bash
terraform output
```

---

## CI/CD Pipeline Stages

| Stage  | Action                          |
| ------ | ------------------------------- |
| Clone  | Pull code from GitHub           |
| Build  | Build Docker image              |
| Test   | Validate container              |
| Push   | Push image to ECR               |
| Deploy | App server pulls and runs image |

---

## Monitoring (CloudWatch)

* Jenkins CPU Alarm
* App CPU Alarm
* Log groups for Jenkins, Apache, and user data scripts

---

## Design Decisions

| Decision             | Reason                      |
| -------------------- | --------------------------- |
| Separate servers     | Production-style separation |
| Elastic IPs          | Stable public access        |
| S3 + DynamoDB        | Safe remote state           |
| Apache reverse proxy | Clean container exposure    |
| ECR lifecycle        | Reduce storage cost         |

---

## Outcome

This project demonstrates real-world DevOps practices:

* Infrastructure as Code
* CI/CD automation
* Containerized deployment
* Monitoring and logging
* Professional architecture and repository structure

> ✅ A complete, automated, production-style DevOps environment built from scratch
