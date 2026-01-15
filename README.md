# Cloud Infrastructure as Code - AWS Terraform 🏗️

**Production-grade AWS infrastructure** powering a highly available, auto-scaling, cloud-native web application. Complete Infrastructure as Code (IaC) implementation using Terraform, managing 95+ AWS resources across multiple availability zones with enterprise security, monitoring, and zero-downtime deployment capabilities.

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Multi--AZ-FF9900)](https://aws.amazon.com/)
[![Infrastructure](https://img.shields.io/badge/Resources-95+-success)](./main.tf)
[![Security](https://img.shields.io/badge/Security-Enterprise--Grade-red)](https://aws.amazon.com/security/)

---

## 🎯 Infrastructure Overview

This Terraform configuration deploys a **complete three-tier, highly available web application infrastructure** on AWS with:

- **Multi-AZ Deployment** across 6 availability zones for maximum fault tolerance
- **Auto-Scaling** infrastructure (3-5 EC2 instances) with Application Load Balancer
- **Serverless Email Verification** using Lambda, SNS, and SES
- **Encrypted Storage** at rest and in transit with KMS (4 separate keys, 90-day rotation)
- **Comprehensive Monitoring** with CloudWatch logs and custom metrics
- **Zero-Downtime Deployments** via automated instance refresh
- **Private Networking** for application and database layers
- **SSL/TLS Termination** with AWS Certificate Manager

---

## 📋 Table of Contents

- [Architecture](#architecture)
- [AWS Services Used](#aws-services-used)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Infrastructure Components](#infrastructure-components)
- [Security](#security)
- [Monitoring](#monitoring)
- [CI/CD Integration](#cicd-integration)
- [Multi-Environment Setup](#multi-environment-setup)
- [Troubleshooting](#troubleshooting)
- [Cost Optimization](#cost-optimization)

---

## 🏗️ Architecture

### **High-Level Architecture**
```
┌─────────────────────────────────────────────────────────────────────┐
│                          Internet Gateway                            │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │   Route53 (DNS + SSL)   │
                    └────────────┬────────────┘
                                 │
              ┌──────────────────┴──────────────────┐
              │  Application Load Balancer (Public) │
              │        HTTPS:443 / HTTP:80          │
              └──────────────────┬──────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
    ┌────▼────┐            ┌────▼────┐            ┌────▼────┐
    │   AZ    │            │   AZ    │            │   AZ    │
    │ Public  │            │ Public  │            │ Public  │
    │ Subnet  │            │ Subnet  │     ...    │ Subnet  │
    └────┬────┘            └────┬────┘            └────┬────┘
         │                      │                      │
    ┌────▼────┐            ┌────▼────┐            ┌────▼────┐
    │  EC2    │            │  EC2    │            │  EC2    │
    │Instance │            │Instance │     ...    │Instance │
    │(Private)│            │(Private)│            │(Private)│
    └────┬────┘            └────┬────┘            └────┬────┘
         │                      │                      │
         └──────────────────────┼──────────────────────┘
                                │
              ┌─────────────────┼─────────────────┐
              │                 │                 │
         ┌────▼─────┐    ┌─────▼──────┐   ┌─────▼──────┐
         │    RDS   │    │     S3     │   │   Lambda   │
         │PostgreSQL│    │   Bucket   │   │  (Email)   │
         │(Multi-AZ)│    │   (KMS)    │   │  ← SNS     │
         │(Private) │    └────────────┘   └─────┬──────┘
         └──────────┘                           │
                                          ┌─────▼──────┐
                                          │    SES     │
                                          │  (Email)   │
                                          └────────────┘
```

### **Network Architecture**
```
VPC: 10.0.0.0/16
│
├── 7 Public Subnets (Internet-facing)
│   ├── Round-robin across 6 Availability Zones
│   └── Hosts: ALB, NAT Gateways
│
└── 7 Private Subnets (Internal)
    ├── Round-robin across 6 Availability Zones
    ├── Application Tier: EC2 Instances (Auto Scaling)
    └── Database Tier: RDS PostgreSQL (Multi-AZ)
```

### **Key Design Patterns**

- **Three-Tier Architecture** - Public (ALB), Application (EC2), Database (RDS)
- **Multi-AZ Deployment** - Fault tolerance across 6 availability zones
- **Defense in Depth** - Multiple layers of security groups
- **Least Privilege** - IAM roles with minimal required permissions
- **Encryption Everywhere** - KMS encryption for all storage services
- **Infrastructure as Code** - 100% reproducible via Terraform
- **Immutable Infrastructure** - Replace, don't modify (AMI-based)

---

## ☁️ AWS Services Used

### **Compute & Networking**
- **VPC** - Virtual Private Cloud with custom CIDR
- **EC2** - Auto-scaled application servers (3-5 instances)
- **Auto Scaling Groups** - Dynamic capacity management
- **Launch Templates** - Immutable instance configuration
- **Application Load Balancer** - HTTPS traffic distribution
- **Target Groups** - Health-checked instance routing
- **Lambda** - Serverless email verification (Node.js 18.x)
- **Internet Gateway** - Public internet access
- **NAT Gateway** - Outbound internet for private subnets
- **Route Tables** - Network traffic routing
- **Subnets** - 14 total (7 public + 7 private across 6 AZs)
- **Security Groups** - Stateful firewalls (ALB, App, DB, Lambda)
- **Route53** - DNS management and health checks
- **Certificate Manager** - SSL/TLS certificates with auto-renewal

### **Storage & Database**
- **RDS PostgreSQL 14** - Multi-AZ relational database
- **S3** - Object storage with lifecycle policies
- **EBS** - Encrypted block storage for EC2 (gp2, 25GB)

### **Security & Secrets**
- **KMS** - 4 separate encryption keys with 90-day rotation
- **Secrets Manager** - Encrypted database credentials
- **IAM** - Roles and policies for service permissions

### **Messaging & Notifications**
- **SNS** - Topic for user registration events
- **SES** - Transactional email delivery

### **Monitoring & Logging**
- **CloudWatch Logs** - 4 segregated log groups
- **CloudWatch Metrics** - Custom application metrics

### **Data & State**
- **DynamoDB** - Email verification token storage

---

## 📦 Project Structure
```
tf-aws-infra-fork/
├── .github/
│   └── workflows/
│       └── terraform-check.yml     # Terraform validation CI
├── .terraform/                     # Terraform providers (generated)
├── lambda/                         # Lambda function source code
│
├── .gitignore                      # Git exclusions
├── .terraform.lock.hcl             # Provider version lock
│
├── acm.tf                          # SSL/TLS certificates
├── demoo.tfvars                    # DEMO environment config
├── devv.tfvars                     # DEV environment config
├── dynamodb.tf                     # Email verification table
├── iam_lambda.tf                   # Lambda IAM roles
├── kms.tf                          # Encryption keys (90-day rotation)
├── lambda.tf                       # Lambda configuration
├── main.tf                         # Core infrastructure (VPC, EC2, ALB, RDS)
├── outputs.tf                      # Terraform outputs
├── secrets.tf                      # Secrets Manager config
├── sns.tf                          # SNS topic configuration
├── variables.tf                    # Input variables
│
├── LICENSE                         # MIT License
├── package-lambda.sh               # Lambda packaging script
├── user-data.sh                    # EC2 initialization script
│
└── README.md                       # This file
```

### **Key Terraform Files**

| File | Purpose |
|------|---------|
| `main.tf` | Core infrastructure (95+ resources) |
| `variables.tf` | Configurable parameters |
| `outputs.tf` | Infrastructure outputs |
| `devv.tfvars` | DEV environment values |
| `demoo.tfvars` | DEMO environment values |
| `acm.tf` | SSL/TLS certificate management |
| `kms.tf` | 4 KMS keys with rotation |
| `lambda.tf` | Serverless email function |
| `sns.tf` | Event notification system |
| `dynamodb.tf` | Token storage table |
| `iam_lambda.tf` | Lambda permissions |
| `secrets.tf` | Secure credential storage |

---

## 📋 Prerequisites

### **Required Tools**
- **Terraform** 1.5+ ([Download](https://www.terraform.io/downloads))
- **AWS CLI** configured with credentials ([Setup](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html))
- **Git** for version control

### **AWS Permissions Required**

IAM user/role must have permissions to create:
- VPC and networking resources
- EC2, Auto Scaling, Load Balancers
- RDS databases and S3 buckets
- Lambda functions and SNS topics
- IAM roles, KMS keys, CloudWatch resources
- Route53 records and ACM certificates

### **Multi-Account Setup**

- **DEV Account** - Development environment
- **DEMO Account** - Production-like environment
- **Root Account** - Domain management (Route53)

---

## ⚡ Quick Start

### **1. Clone Repository**
```bash
git clone https://github.com/YourOrg/tf-aws-infra-fork.git
cd tf-aws-infra-fork
```

### **2. Configure AWS Credentials**
```bash
aws configure --profile dev
# Enter: Access Key ID, Secret Key, Region (us-east-1)
```

### **3. Initialize Terraform**
```bash
terraform init
```

### **4. Configure Variables**

Edit `devv.tfvars`:
```hcl
aws_account_id = "YOUR_ACCOUNT_ID"
aws_region     = "us-east-1"
ami_id         = "ami-xxxxx"  # Your custom AMI
subdomain      = "dev"
domain_name    = "yourdomain.com"
hosted_zone_id = "ZXXXXX"
```

### **5. Deploy**
```bash
# Plan
terraform plan -var-file=devv.tfvars

# Apply
terraform apply -var-file=devv.tfvars
```

**Deployment time:** ~15-20 minutes

---

## ⚙️ Configuration

### **Core Variables**
```hcl
# AWS
aws_account_id = "YOUR_ACCOUNT_ID"
aws_region     = "us-east-1"
ami_id         = "ami-xxxxx"

# Network
vpc_cidr = "10.0.0.0/16"

# Auto Scaling
asg_min_size         = 3
asg_max_size         = 5
asg_desired_capacity = 3

# Database
db_name              = "csye6225"
db_instance_class    = "db.t3.micro"
db_multi_az          = true

# Domain
domain_name    = "yourdomain.com"
subdomain      = "dev"
hosted_zone_id = "ZXXXXX"
```

---

## 🚀 Deployment

### **Initial Deployment**
```bash
terraform init
terraform validate
terraform plan -var-file=devv.tfvars
terraform apply -var-file=devv.tfvars
```

### **Update Infrastructure**
```bash
terraform plan -var-file=devv.tfvars
terraform apply -var-file=devv.tfvars
```

### **Destroy Resources**
```bash
# ⚠️ WARNING: Deletes all resources
terraform destroy -var-file=devv.tfvars
```

---

## 🧩 Infrastructure Components

### **1. VPC & Networking**

- **VPC:** 10.0.0.0/16
- **14 Subnets:** 7 public + 7 private across 6 AZs
- **NAT Gateways:** For private subnet internet access
- **Internet Gateway:** Public internet connectivity
- **Route Tables:** Separate for public/private subnets

---

### **2. Security Groups**

**ALB Security Group:**
- HTTPS (443) from internet
- HTTP (80) redirects to HTTPS

**Application Security Group:**
- Port 8080 from ALB only
- All outbound traffic

**Database Security Group:**
- PostgreSQL (5432) from app tier only

**Lambda Security Group:**
- HTTPS (443) for SES, DynamoDB

---

### **3. Auto Scaling Group**

**Configuration:**
- Min: 3, Max: 5, Desired: 3
- Target CPU: 5%
- Health checks: ELB
- Instance refresh: Rolling (80% min healthy)

**Launch Template:**
- AMI: Custom built with Packer
- Instance type: t2.micro
- EBS: 25GB encrypted (KMS)
- IAM role: EC2 with CloudWatch + S3 + SNS

---

### **4. Application Load Balancer**

**Listeners:**
- HTTPS:443 → Forward to target group
- HTTP:80 → Redirect to HTTPS (301)

**Target Group:**
- Health check: `/healthz`
- Interval: 30s
- Healthy threshold: 2

---

### **5. RDS PostgreSQL**

**Configuration:**
- Engine: PostgreSQL 14
- Instance: db.t3.micro
- Multi-AZ: Enabled
- Encrypted: KMS
- Backups: 7-day retention

---

### **6. S3 Bucket**

**Features:**
- UUID-based bucket name
- KMS encryption
- Lifecycle: Standard → Standard-IA (30 days)
- Public access: Blocked

---

### **7. Lambda Function**

**Email Verification:**
- Runtime: Node.js 18.x
- Trigger: SNS topic
- Timeout: 60s
- VPC: Private subnets

**Workflow:**
1. User registers → SNS publishes event
2. Lambda receives event
3. Generates verification link
4. Stores token in DynamoDB (1-minute TTL)
5. Sends email via SES

---

### **8. KMS Encryption**

**4 Separate Keys:**
1. **EC2 Key** - EBS volume encryption
2. **RDS Key** - Database encryption
3. **S3 Key** - Bucket encryption
4. **Secrets Key** - Secrets Manager

**All keys:** 90-day automatic rotation

---

### **9. CloudWatch Logging**

**4 Log Groups:**
- `/csye6225/{env}/webapp/info`
- `/csye6225/{env}/webapp/warn`
- `/csye6225/{env}/webapp/error`
- `/csye6225/{env}/webapp/deployment`

**Retention:** 7 days

---

### **10. SSL/TLS**

**ACM Certificate:**
- Domain: `{subdomain}.{domain}`
- Validation: DNS (Route53)
- Auto-renewal: Enabled

**Route53:**
- A record → ALB alias

---

## 🔐 Security

### **Network Security**
- **Defense in Depth** - Public → Private → Database layers
- **Security Groups** - Least privilege access
- **No Direct Access** - All traffic through ALB
- **Private Subnets** - App and DB isolated

### **Encryption**
- **At Rest:** KMS encryption (EBS, RDS, S3, Secrets)
- **In Transit:** TLS 1.2+ via ACM certificates
- **Key Rotation:** Automatic 90-day rotation

### **Access Control**
- **IAM Roles** - Separate for EC2, Lambda, Auto Scaling
- **Least Privilege** - Minimum required permissions
- **No Hardcoded Credentials** - Secrets Manager integration

### **Password Management**
- Auto-generated (20 chars, special chars)
- Stored in Secrets Manager (KMS encrypted)
- Injected via user-data at launch

---

## 📊 Monitoring

### **CloudWatch Logs**
- Segregated by log level (info/warn/error)
- 7-day retention
- Real-time streaming

### **CloudWatch Metrics**
- ALB: Request count, latency, errors
- Auto Scaling: Instance count, CPU
- RDS: Connections, CPU, storage
- Lambda: Invocations, duration, errors

### **Health Checks**
- **ALB:** `/healthz` every 30s
- **Auto Scaling:** ELB-based
- **Grace Period:** 5 minutes

---

## 🔄 CI/CD Integration

### **Terraform Validation**
```yaml
# .github/workflows/terraform-check.yml
name: Terraform Validation
on: [pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - run: terraform fmt -check
      - run: terraform init
      - run: terraform validate
```

### **Application Deployment Flow**

1. Push to `main` → Build AMI
2. Extract new AMI ID
3. Update Launch Template
4. Trigger instance refresh (zero downtime)
5. Validate deployment

---

## 🌍 Multi-Environment Setup

### **Environments**

**DEV (`devv.tfvars`):**
- Development and testing
- Smaller instance types

**DEMO (`demoo.tfvars`):**
- Production-like environment
- Larger instances, enhanced monitoring

### **Deploy Multiple Environments**
```bash
# DEV
terraform workspace select dev
terraform apply -var-file=devv.tfvars

# DEMO
terraform workspace select demo
terraform apply -var-file=demoo.tfvars
```

---

## 🐛 Troubleshooting

### **Common Issues**

**Terraform Init Fails:**
```bash
rm -rf .terraform .terraform.lock.hcl
terraform init
```

**AMI Not Found:**
```bash
aws ec2 describe-images --image-ids ami-xxxxx
```

**Certificate Timeout:**
- Verify Route53 hosted zone ID
- Wait 5-10 minutes for DNS propagation

**Instances Unhealthy:**
```bash
# Check target health
aws elbv2 describe-target-health --target-group-arn <arn>

# Check logs
aws logs tail /csye6225/dev/webapp/deployment --follow
```

### **Debugging**
```bash
# Enable debug logging
export TF_LOG=DEBUG

# Show state
terraform show

# Inspect resource
terraform state show aws_autoscaling_group.csye6225_asg
```
---

## 📚 Additional Resources

### **Related Repositories**
- **Application Code:** `webapp-fork` - Node.js/Express REST API
- **Serverless Functions:** `serverless-fork` - Lambda email verification

---

## 📄 License

MIT License - Academic project

---

## 🌟 Key Features Summary

✅ **95+ AWS Resources** managed by Terraform  
✅ **Multi-AZ High Availability** across 6 availability zones  
✅ **14 Subnets** (7 public + 7 private) with round-robin distribution  
✅ **Auto-Scaling Infrastructure** (3-5 instances)  
✅ **Zero-Downtime Deployments** via instance refresh  
✅ **Enterprise Security** - 4 KMS keys, 90-day rotation  
✅ **Comprehensive Monitoring** - Segregated CloudWatch logs  
✅ **Serverless Integration** - Lambda email verification  
✅ **SSL/TLS Encryption** - ACM certificates  
✅ **Complete Automation** - CI/CD integrated

**Production-ready infrastructure showcasing enterprise-grade cloud architecture!** 🎉