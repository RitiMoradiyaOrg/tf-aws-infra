# Cloud Infrastructure as Code - AWS Terraform 🏗️

**Production-grade AWS infrastructure** powering a highly available, auto-scaling, cloud-native web application. Complete Infrastructure as Code (IaC) implementation using Terraform, managing 95+ AWS resources across multiple availability zones with enterprise security, monitoring, and zero-downtime deployment capabilities.

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Multi--AZ-FF9900)](https://aws.amazon.com/)
[![Infrastructure](https://img.shields.io/badge/Resources-95+-success)](./main.tf)
[![Security](https://img.shields.io/badge/Security-Enterprise--Grade-red)](https://aws.amazon.com/security/)

---

## 🎯 Infrastructure Overview

This Terraform configuration deploys a **complete three-tier, highly available web application infrastructure** on AWS with:

- **Multi-AZ Deployment** across 3 availability zones for fault tolerance
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
    │  AZ-1   │            │  AZ-2   │            │  AZ-3   │
    │ Public  │            │ Public  │            │ Public  │
    │ Subnet  │            │ Subnet  │            │ Subnet  │
    └────┬────┘            └────┬────┘            └────┬────┘
         │                      │                      │
    ┌────▼────┐            ┌────▼────┐            ┌────▼────┐
    │  EC2    │            │  EC2    │            │  EC2    │
    │Instance │            │Instance │            │Instance │
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
├── Public Subnets (Internet-facing)
│   ├── 10.0.1.0/24 (us-east-1a) - ALB, NAT Gateway
│   ├── 10.0.2.0/24 (us-east-1b) - ALB, NAT Gateway  
│   └── 10.0.3.0/24 (us-east-1c) - ALB, NAT Gateway
│
└── Private Subnets (Internal)
    ├── Application Tier
    │   ├── 10.0.4.0/24 (us-east-1a) - EC2 Instances
    │   ├── 10.0.5.0/24 (us-east-1b) - EC2 Instances
    │   └── 10.0.6.0/24 (us-east-1c) - EC2 Instances
    │
    └── Database Tier
        ├── 10.0.7.0/24 (us-east-1a) - RDS Primary
        ├── 10.0.8.0/24 (us-east-1b) - RDS Standby
        └── 10.0.9.0/24 (us-east-1c) - Future use
```

### **Key Design Patterns**

- **Three-Tier Architecture** - Public (ALB), Application (EC2), Database (RDS)
- **Multi-AZ Deployment** - Fault tolerance across 3 availability zones
- **Defense in Depth** - Multiple layers of security groups
- **Least Privilege** - IAM roles with minimal required permissions
- **Encryption Everywhere** - KMS encryption for all storage services
- **Infrastructure as Code** - 100% reproducible via Terraform
- **Immutable Infrastructure** - Replace, don't modify (AMI-based)

---

## ☁️ AWS Services Used

### **Compute & Networking (16 services)**
- **VPC** - Virtual Private Cloud with custom CIDR
- **EC2** - Auto-scaled application servers (3-5 instances)
- **Auto Scaling Groups** - Dynamic capacity management
- **Launch Templates** - Immutable instance configuration
- **Application Load Balancer** - HTTPS traffic distribution
- **Target Groups** - Health-checked instance routing
- **Lambda** - Serverless email verification (Node.js 18.x)
- **Internet Gateway** - Public internet access
- **NAT Gateway** - Outbound internet for private subnets (3x)
- **Route Tables** - Network traffic routing (4x)
- **Subnets** - Network segmentation (9 total: 3 public, 6 private)
- **Security Groups** - Stateful firewalls (4x: ALB, App, DB, Lambda)
- **Route53** - DNS management and health checks
- **Certificate Manager** - SSL/TLS certificates with auto-renewal

### **Storage & Database (3 services)**
- **RDS PostgreSQL 14** - Multi-AZ relational database
- **S3** - Object storage with lifecycle policies
- **EBS** - Encrypted block storage for EC2 (gp2, 25GB)

### **Security & Secrets (3 services)**
- **KMS** - 4 separate encryption keys with 90-day rotation
  - EC2 EBS volumes
  - RDS database
  - S3 bucket
  - Secrets Manager
- **Secrets Manager** - Encrypted database credentials
- **IAM** - 6 roles, 8 policies for service permissions

### **Messaging & Notifications (2 services)**
- **SNS** - Topic for user registration events
- **SES** - Transactional email delivery

### **Monitoring & Logging (2 services)**
- **CloudWatch Logs** - 4 segregated log groups (info/warn/error/deployment)
- **CloudWatch Metrics** - Custom application metrics

### **Data & State (1 service)**
- **DynamoDB** - Email verification token storage

---

## 📦 Project Structure
```
tf-aws-infra-fork/
├── main.tf                     # Core infrastructure resources
├── variables.tf                # Input variable definitions
├── outputs.tf                  # Output values (VPC ID, subnets, etc.)
├── devv.tfvars                 # DEV environment configuration
├── demoo.tfvars                # DEMO environment configuration
├── .github/workflows/
│   └── terraform-check.yml     # Terraform validation CI
├── .gitignore                  # Terraform state exclusions
└── README.md                   # This file
```

### **Key Files**

**`main.tf`** - Contains all infrastructure resources:
- VPC and networking (subnets, route tables, gateways)
- Security groups with layered security
- Auto Scaling Group with launch template
- Application Load Balancer with SSL/TLS
- RDS PostgreSQL Multi-AZ
- S3 bucket with encryption
- Lambda function for email verification
- SNS topic and subscription
- KMS keys with rotation policies
- IAM roles and policies
- CloudWatch log groups
- Route53 DNS records
- Secrets Manager for database credentials

**`variables.tf`** - Configurable parameters:
- AWS account and region
- AMI ID for EC2 instances
- VPC CIDR and subnet configuration
- Instance types and scaling limits
- Database configuration
- Domain name and SSL settings
- Environment-specific tags

**`*.tfvars`** - Environment-specific values:
- `devv.tfvars` - DEV environment configuration
- `demoo.tfvars` - DEMO environment configuration

---

## 📋 Prerequisites

### **Required Tools**
- **Terraform** 1.5 or higher ([Download](https://www.terraform.io/downloads))
- **AWS CLI** configured with appropriate credentials ([Setup Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html))
- **Git** for version control
- **Valid AWS Account** with appropriate permissions

### **AWS Permissions Required**

The IAM user/role must have permissions to create:
- VPC and networking resources
- EC2, Auto Scaling, and Load Balancers
- RDS databases
- S3 buckets
- Lambda functions
- IAM roles and policies
- KMS keys
- CloudWatch resources
- Route53 records
- Certificate Manager certificates

### **AWS Account Setup**

This infrastructure supports **multi-account deployment**:
- **DEV Account** - Development environment
- **DEMO Account** - Production-like environment
- **Root Account** - Domain management (Route53 hosted zone)

---

## ⚡ Quick Start

### **1. Clone Repository**
```bash
git clone https://github.com/RitiMoradiyaOrg/tf-aws-infra-fork.git
cd tf-aws-infra-fork
```

### **2. Configure AWS Credentials**
```bash
# Configure AWS CLI profiles
aws configure --profile dev
# Enter AWS Access Key ID, Secret Access Key, Region (us-east-1)

aws configure --profile demo
# Enter AWS Access Key ID, Secret Access Key, Region (us-east-1)
```

### **3. Initialize Terraform**
```bash
terraform init
```

### **4. Configure Environment Variables**

Edit `devv.tfvars` with your specific values:
```hcl
aws_account_id = "YOUR_AWS_ACCOUNT_ID"
aws_region     = "us-east-1"
ami_id         = "ami-xxxxxxxxxxxxxxxxx"  # Your custom AMI from Packer
subdomain      = "dev"                     # dev.yourdomain.com
domain_name    = "yourdomain.com"
hosted_zone_id = "ZXXXXXXXXXXXXX"          # Your Route53 hosted zone ID
# ... other variables
```

### **5. Plan Deployment**
```bash
# Review what will be created
terraform plan -var-file=devv.tfvars
```

### **6. Deploy Infrastructure**
```bash
# Apply configuration
terraform apply -var-file=devv.tfvars

# Confirm with 'yes' when prompted
```

### **7. Verify Deployment**
```bash
# Get outputs
terraform output

# Test health endpoint
curl https://dev.yourdomain.com/healthz
```

---

## ⚙️ Configuration

### **Required Variables**

Edit `devv.tfvars` or `demoo.tfvars`:
```hcl
# AWS Configuration
aws_account_id = "YOUR_AWS_ACCOUNT_ID"
aws_region     = "us-east-1"
aws_profile    = "dev"

# AMI Configuration
ami_id = "ami-xxxxxxxxxxxxxxxxx"  # Your custom AMI from Packer

# VPC Configuration
vpc_cidr = "10.0.0.0/16"

# Subnets (3 AZs × 3 tiers = 9 subnets)
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
db_subnet_cidrs      = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24"]

# Instance Configuration
instance_type      = "t2.micro"
volume_size        = 25
volume_type        = "gp2"
delete_on_termination = true

# Auto Scaling Configuration
asg_min_size         = 3
asg_max_size         = 5
asg_desired_capacity = 3
asg_cooldown         = 60

# Database Configuration
db_name              = "csye6225"
db_username          = "csye6225"
db_instance_class    = "db.t3.micro"
db_allocated_storage = 20
db_engine            = "postgres"
db_engine_version    = "14"
db_multi_az          = true
db_publicly_accessible = false

# Domain Configuration
domain_name = "yourdomain.com"
subdomain   = "dev"                        # dev.yourdomain.com
hosted_zone_id = "ZXXXXXXXXXXXXX"          # Your Route53 hosted zone ID

# Lambda Configuration
lambda_runtime = "nodejs18.x"
lambda_handler = "index.handler"
lambda_zip     = "lambda-email-verification.zip"

# Email Configuration
ses_email_from = "noreply@yourdomain.com"

# Tags
environment = "dev"
project     = "csye6225"
```

### **Optional Variables**
```hcl
# Scaling Policy
target_cpu_utilization = 5.0  # Target 5% CPU for aggressive scaling

# Instance Refresh Settings
min_healthy_percentage = 80   # Keep 80% healthy during refresh
instance_warmup        = 300  # 5 minutes warmup time

# RDS Backup
db_backup_retention_period = 7  # 7 days backup retention

# S3 Lifecycle
s3_transition_days = 30  # Move to Standard-IA after 30 days
```

---

## 🚀 Deployment

### **Initial Deployment**
```bash
# 1. Initialize Terraform
terraform init

# 2. Validate configuration
terraform validate

# 3. Plan deployment
terraform plan -var-file=devv.tfvars

# 4. Apply configuration
terraform apply -var-file=devv.tfvars

# Expected time: 15-20 minutes
```

### **Update Existing Infrastructure**
```bash
# 1. Make changes to .tf files or .tfvars

# 2. Plan changes
terraform plan -var-file=devv.tfvars

# 3. Apply updates
terraform apply -var-file=devv.tfvars
```

### **Destroy Infrastructure**
```bash
# ⚠️ WARNING: This will delete ALL resources!

terraform destroy -var-file=devv.tfvars
```

### **Selective Updates**
```bash
# Update only Auto Scaling Group
terraform apply -target=aws_autoscaling_group.csye6225_asg -var-file=devv.tfvars

# Update only RDS instance
terraform apply -target=aws_db_instance.csye6225 -var-file=devv.tfvars

# Update only Lambda function
terraform apply -target=aws_lambda_function.email_verification -var-file=devv.tfvars
```

---

## 🧩 Infrastructure Components

### **1. VPC & Networking**

**VPC Configuration:**
```hcl
resource "aws_vpc" "csye6225_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}
```

**Subnets:**
- **3 Public Subnets** - For ALB and NAT Gateways
- **3 Private Subnets** - For EC2 instances
- **3 Database Subnets** - For RDS Multi-AZ

**Route Tables:**
- **Public Route Table** - Routes to Internet Gateway
- **Private Route Tables (3x)** - Routes to NAT Gateways (one per AZ)

**NAT Gateways:**
- One per availability zone for high availability
- Provides outbound internet for private subnets

---

### **2. Security Groups**

**ALB Security Group:**
- Inbound: HTTPS (443) from 0.0.0.0/0
- Inbound: HTTP (80) from 0.0.0.0/0 (redirects to HTTPS)
- Outbound: All traffic

**Application Security Group:**
- Inbound: Port 8080 from ALB Security Group
- Outbound: All traffic

**Database Security Group:**
- Inbound: PostgreSQL (5432) from Application Security Group
- Outbound: PostgreSQL (5432) to Application Security Group

**Lambda Security Group:**
- Inbound: None (Lambda initiates connections)
- Outbound: HTTPS (443) for SES, DynamoDB

---

### **3. Auto Scaling Group**

**Launch Template:**
```hcl
resource "aws_launch_template" "csye6225_lt" {
  name          = "csye6225-launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type
  
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 25
      volume_type = "gp2"
      encrypted   = true
      kms_key_id  = aws_kms_key.ec2_key.arn
    }
  }
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.application.id]
  }
  
  user_data = base64encode(templatefile("user-data.sh", {
    DB_HOST     = aws_db_instance.csye6225.address
    DB_NAME     = var.db_name
    DB_USER     = var.db_username
    DB_PASSWORD = random_password.db_password.result
    S3_BUCKET   = aws_s3_bucket.csye6225.bucket
    SNS_TOPIC   = aws_sns_topic.user_registration.arn
    AWS_REGION  = var.aws_region
  }))
}
```

**Auto Scaling Group:**
```hcl
resource "aws_autoscaling_group" "csye6225_asg" {
  name                = "csye6225-asg"
  min_size            = 3
  max_size            = 5
  desired_capacity    = 3
  health_check_type   = "ELB"
  health_check_grace_period = 300
  
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.csye6225_tg.arn]
  
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 80
      instance_warmup        = 300
      checkpoint_percentages = [50, 100]
      checkpoint_delay       = 300
    }
  }
}
```

**Scaling Policy:**
```hcl
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.csye6225_asg.name
  policy_type            = "TargetTrackingScaling"
  
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 5.0  # Scale at 5% CPU
  }
}
```

---

### **4. Application Load Balancer**

**Load Balancer:**
```hcl
resource "aws_lb" "csye6225_alb" {
  name               = "csye6225-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer.id]
  subnets            = aws_subnet.public[*].id
}
```

**Target Group:**
```hcl
resource "aws_lb_target_group" "csye6225_tg" {
  name     = "csye6225-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.csye6225_vpc.id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/healthz"
    protocol            = "HTTP"
    matcher             = "200"
  }
}
```

**Listeners:**
```hcl
# HTTPS Listener (443)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.csye6225_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.csye6225_cert.arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.csye6225_tg.arn
  }
}

# HTTP Listener (80) - Redirect to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.csye6225_alb.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
```

---

### **5. RDS PostgreSQL**

**Database Instance:**
```hcl
resource "aws_db_instance" "csye6225" {
  identifier             = "csye6225"
  engine                 = "postgres"
  engine_version         = "14"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.rds_key.arn
  
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result
  
  multi_az               = true
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.csye6225.name
  vpc_security_group_ids = [aws_security_group.database.id]
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"
  
  skip_final_snapshot = true
}
```

**Subnet Group:**
```hcl
resource "aws_db_subnet_group" "csye6225" {
  name       = "csye6225-db-subnet-group"
  subnet_ids = aws_subnet.db[*].id
}
```

**Password Management:**
```hcl
resource "random_password" "db_password" {
  length  = 20
  special = true
}

resource "aws_secretsmanager_secret" "db_password" {
  name       = "csye6225-db-password"
  kms_key_id = aws_kms_key.secrets_key.arn
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}
```

---

### **6. S3 Bucket**

**Bucket Configuration:**
```hcl
resource "aws_s3_bucket" "csye6225" {
  bucket        = random_uuid.s3_bucket_name.result
  force_destroy = true
}

resource "aws_s3_bucket_encryption_configuration" "csye6225" {
  bucket = aws_s3_bucket.csye6225.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_key.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "csye6225" {
  bucket = aws_s3_bucket.csye6225.id
  
  rule {
    id     = "transition-to-ia"
    status = "Enabled"
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "csye6225" {
  bucket = aws_s3_bucket.csye6225.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

---

### **7. Lambda Function (Email Verification)**

**Lambda Function:**
```hcl
resource "aws_lambda_function" "email_verification" {
  function_name = "emailVerificationLambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  filename      = var.lambda_zip
  timeout       = 60
  
  environment {
    variables = {
      SES_EMAIL_FROM = var.ses_email_from
      DOMAIN_NAME    = "${var.subdomain}.${var.domain_name}"
      DYNAMODB_TABLE = aws_dynamodb_table.email_verification.name
    }
  }
  
  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }
}
```

**SNS Topic & Subscription:**
```hcl
resource "aws_sns_topic" "user_registration" {
  name = "user-registration"
}

resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.user_registration.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.email_verification.arn
}

resource "aws_lambda_permission" "sns_invoke" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.email_verification.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.user_registration.arn
}
```

**DynamoDB Table:**
```hcl
resource "aws_dynamodb_table" "email_verification" {
  name           = "EmailVerification"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "email"
  
  attribute {
    name = "email"
    type = "S"
  }
  
  ttl {
    enabled        = true
    attribute_name = "ttl"
  }
}
```

---

### **8. KMS Encryption**

**Four Separate KMS Keys:**
```hcl
# EC2 EBS Encryption Key
resource "aws_kms_key" "ec2_key" {
  description             = "KMS key for EC2 EBS volumes"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow service-linked role use of the key"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        }
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow Auto Scaling to create grants"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        }
        Action = "kms:CreateGrant"
        Resource = "*"
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
        }
      }
    ]
  })
}

# RDS Encryption Key
resource "aws_kms_key" "rds_key" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90
}

# S3 Encryption Key
resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90
}

# Secrets Manager Encryption Key
resource "aws_kms_key" "secrets_key" {
  description             = "KMS key for Secrets Manager"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90
}
```

---

### **9. CloudWatch Logging**

**Log Groups:**
```hcl
resource "aws_cloudwatch_log_group" "webapp_info" {
  name              = "/csye6225/${var.subdomain}/webapp/info"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "webapp_warn" {
  name              = "/csye6225/${var.subdomain}/webapp/warn"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "webapp_error" {
  name              = "/csye6225/${var.subdomain}/webapp/error"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "webapp_deployment" {
  name              = "/csye6225/${var.subdomain}/webapp/deployment"
  retention_in_days = 7
}
```

---

### **10. SSL/TLS Certificates**

**ACM Certificate:**
```hcl
resource "aws_acm_certificate" "csye6225_cert" {
  domain_name       = "${var.subdomain}.${var.domain_name}"
  validation_method = "DNS"
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.csye6225_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  
  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  zone_id         = var.hosted_zone_id
  records         = [each.value.record]
  ttl             = 60
}

resource "aws_acm_certificate_validation" "csye6225_cert" {
  certificate_arn         = aws_acm_certificate.csye6225_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
```

**Route53 DNS:**
```hcl
resource "aws_route53_record" "csye6225_a" {
  zone_id = var.hosted_zone_id
  name    = "${var.subdomain}.${var.domain_name}"
  type    = "A"
  
  alias {
    name                   = aws_lb.csye6225_alb.dns_name
    zone_id                = aws_lb.csye6225_alb.zone_id
    evaluate_target_health = true
  }
}
```

---

### **11. IAM Roles & Policies**

**EC2 Instance Role:**
```hcl
resource "aws_iam_role" "ec2_role" {
  name = "EC2-CSYE6225"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy" "s3_access" {
  name = "S3Access"
  role = aws_iam_role.ec2_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ]
      Resource = "${aws_s3_bucket.csye6225.arn}/*"
    }]
  })
}

resource "aws_iam_role_policy" "sns_publish" {
  name = "SNSPublish"
  role = aws_iam_role.ec2_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sns:Publish"
      Resource = aws_sns_topic.user_registration.arn
    }]
  })
}
```

**Lambda Execution Role:**
```hcl
resource "aws_iam_role" "lambda_role" {
  name = "LambdaExecutionRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "lambda_ses" {
  name = "LambdaSESPolicy"
  role = aws_iam_role.lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ses:SendEmail",
        "ses:SendRawEmail"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "LambdaDynamoDBPolicy"
  role = aws_iam_role.lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ]
      Resource = aws_dynamodb_table.email_verification.arn
    }]
  })
}
```

---

## 🔐 Security

### **Network Security**

**Defense in Depth:**
1. **Public Layer** - Only ALB exposed to internet
2. **Application Layer** - EC2 in private subnets
3. **Database Layer** - RDS in isolated private subnets
4. **No Direct Access** - All resources behind security groups

**Security Group Rules:**
- Least privilege access (only required ports)
- Source-based restrictions (not 0.0.0.0/0 internally)
- Stateful firewall rules

---

### **Encryption**

**Data at Rest:**
- **EC2 EBS volumes** - KMS encrypted (gp2)
- **RDS database** - KMS encrypted with Multi-AZ
- **S3 bucket** - Server-side encryption (SSE-KMS)
- **Secrets Manager** - KMS encrypted credentials

**Key Rotation:**
- Automatic 90-day rotation for all KMS keys
- Managed by AWS KMS service
- No application downtime during rotation

**Data in Transit:**
- **HTTPS/TLS** - ALB terminates SSL with ACM certificates
- **TLS 1.2+** - Modern encryption protocols only
- **HTTPS Enforcement** - HTTP redirects to HTTPS (301)

---

### **Access Control**

**IAM Best Practices:**
- Separate roles for EC2, Lambda, Auto Scaling
- Minimum required permissions per role
- No hardcoded credentials
- Service-linked roles for AWS services

**Secrets Management:**
- Database passwords auto-generated (20 chars, special chars)
- Stored in Secrets Manager with KMS encryption
- Injected via user-data at instance launch
- Never committed to version control

---

### **Compliance**

**Security Features:**
- VPC Flow Logs (optional, commented in main.tf)
- CloudTrail logging (optional)
- S3 bucket versioning (optional)
- RDS automated backups (7-day retention)
- Multi-AZ deployment for high availability

---

## 📊 Monitoring

### **CloudWatch Logs**

**Application Logs (Segregated):**
- `/csye6225/{environment}/webapp/info` - INFO level
- `/csye6225/{environment}/webapp/warn` - WARN level
- `/csye6225/{environment}/webapp/error` - ERROR level
- `/csye6225/{environment}/webapp/deployment` - Deployment logs

**Retention:** 7 days (configurable)

---

### **CloudWatch Metrics**

**Auto-Generated Metrics:**
- **ALB Metrics** - Request count, latency, error rates
- **Target Group Metrics** - Healthy/unhealthy hosts
- **Auto Scaling Metrics** - Instance count, CPU utilization
- **RDS Metrics** - Connections, CPU, storage, IOPS
- **Lambda Metrics** - Invocations, duration, errors

**Custom Metrics:**
- Application-level metrics via StatsD
- Business metrics (user registrations, API calls)

---

### **Health Checks**

**ALB Health Checks:**
- **Path:** `/healthz`
- **Interval:** 30 seconds
- **Timeout:** 5 seconds
- **Healthy threshold:** 2 consecutive successes
- **Unhealthy threshold:** 2 consecutive failures

**Auto Scaling Health Checks:**
- **Type:** ELB (based on target group health)
- **Grace period:** 300 seconds (5 minutes)
- **Replacement:** Automatic for unhealthy instances

---

## 🔄 CI/CD Integration

### **Terraform Validation Workflow**

Located in `.github/workflows/terraform-check.yml`:
```yaml
name: Terraform Validation

on:
  pull_request:
    branches: [main]

jobs:
  terraform-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
      
      - name: Terraform Format Check
        run: terraform fmt -check -recursive
      
      - name: Terraform Init
        run: terraform init
      
      - name: Terraform Validate
        run: terraform validate
```

**Purpose:**
- Enforces Terraform formatting standards
- Validates configuration syntax
- Prevents invalid code from merging

---

### **Integration with Application CI/CD**

**Webapp CI/CD Pipeline:**
1. Builds new AMI with Packer
2. Extracts new AMI ID
3. **Updates Launch Template:**
   - Finds latest Launch Template
   - Creates new version with new AMI
   - Sets new version as default
4. **Triggers Instance Refresh:**
   - Finds Auto Scaling Group
   - Starts rolling instance refresh
   - Replaces instances gradually (80% min healthy)
5. Validates deployment success

**This infrastructure supports zero-downtime deployments!**

---

## 🌍 Multi-Environment Setup

### **Environment Separation**

**DEV Environment (`devv.tfvars`):**
- **Purpose:** Development and testing
- **Configuration:** Standard t2.micro instances

**DEMO Environment (`demoo.tfvars`):**
- **Purpose:** Production-like environment
- **Configuration:** Can use larger instances

---

### **Deploying Multiple Environments**
```bash
# Deploy DEV environment
terraform workspace new dev || terraform workspace select dev
terraform apply -var-file=devv.tfvars

# Deploy DEMO environment
terraform workspace new demo || terraform workspace select demo
terraform apply -var-file=demoo.tfvars
```

---

### **Terraform State Management**

**Best Practices:**
```hcl
# Add to main.tf for remote state (recommended for production)
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

**Benefits:**
- Shared state across team
- State locking prevents concurrent modifications
- Encrypted state storage
- Versioned state history

---

## 🐛 Troubleshooting

### **Common Issues**

#### **1. Terraform Init Fails**
```bash
# Error: Failed to initialize backend

# Solution: Clear .terraform directory
rm -rf .terraform .terraform.lock.hcl
terraform init
```

---

#### **2. AMI Not Found**
```bash
# Error: InvalidAMIID.NotFound

# Solution: Verify AMI ID exists in your AWS account
aws ec2 describe-images --image-ids ami-xxxxxxxxxxxxxxxxx

# Update devv.tfvars with correct AMI ID
ami_id = "ami-xxxxxxxxxxxxxxxxx"
```

---

#### **3. Certificate Validation Timeout**
```bash
# Error: Certificate validation timed out

# Solution: Check Route53 hosted zone
# 1. Verify hosted_zone_id in tfvars is correct
# 2. Check DNS validation records were created
aws route53 list-resource-record-sets --hosted-zone-id ZXXXXX

# 3. Wait for DNS propagation (can take 5-10 minutes)
```

---

#### **4. Instances Not Healthy**
```bash
# Check ALB target health
aws elbv2 describe-target-health \
  --target-group-arn <arn> \
  --region us-east-1

# Check instance logs via Systems Manager
aws ssm start-session --target <instance-id>

# Inside instance:
sudo systemctl status webapp
sudo journalctl -u webapp -f
```

---

#### **5. Database Connection Failed**
```bash
# Check security group rules
aws ec2 describe-security-groups \
  --group-ids <db-security-group-id> \
  --region us-east-1

# Verify RDS endpoint is correct
aws rds describe-db-instances \
  --db-instance-identifier csye6225 \
  --region us-east-1
```

---

#### **6. KMS Permission Denied**
```bash
# Error: KMS.DisabledException or AccessDenied

# Solution: Check KMS key policy includes Auto Scaling service role
aws kms get-key-policy \
  --key-id <key-id> \
  --policy-name default \
  --region us-east-1

# Verify service-linked role exists
aws iam get-role \
  --role-name AWSServiceRoleForAutoScaling
```

---

### **Debugging Terraform**
```bash
# Enable detailed logging
export TF_LOG=DEBUG
terraform plan -var-file=devv.tfvars

# Show current state
terraform show

# List all resources
terraform state list

# Inspect specific resource
terraform state show aws_autoscaling_group.csye6225_asg

# Refresh state from AWS
terraform refresh -var-file=devv.tfvars
```

---

### **Terraform Import (Recover Existing Resources)**
```bash
# If resource exists in AWS but not in state

# Import VPC
terraform import aws_vpc.csye6225_vpc vpc-xxxxxxxxxxxxx

# Import Security Group
terraform import aws_security_group.application sg-xxxxxxxxxxxxx

# Import RDS instance
terraform import aws_db_instance.csye6225 csye6225
```

---

## 💰 Cost Optimization

### **Current Monthly Cost Estimate**

| Service | Configuration | Est. Monthly Cost |
|---------|--------------|-------------------|
| **EC2** | 3-5 × t2.micro (average 4) | $35-$50 |
| **EBS** | 4 × 25GB gp2 volumes | $10 |
| **RDS** | 1 × db.t3.micro Multi-AZ | $30-$35 |
| **ALB** | Standard ALB | $22-$25 |
| **NAT Gateway** | 3 × NAT Gateways | $100-$110 |
| **S3** | Standard storage + requests | $5-$10 |
| **Lambda** | Free tier eligible | $0-$1 |
| **CloudWatch** | Logs + Metrics | $5-$10 |
| **Route53** | Hosted zone + queries | $1-$2 |
| **KMS** | 4 keys + requests | $4 |
| **Data Transfer** | Outbound to internet | $10-$20 |
| **Total** | | **~$222-$278/month** |

---

### **Cost Optimization Strategies**

**1. Reduce NAT Gateways (Biggest Cost Driver)**
```hcl
# Option A: Use single NAT Gateway (saves ~$70/month)
# ⚠️ Reduces high availability

# Option B: Remove NAT Gateways, use VPC Endpoints
# For S3, DynamoDB, SES, SNS, CloudWatch
# Saves ~$100/month but requires configuration changes
```

**2. Use Reserved Instances**
```bash
# 1-year reserved instance: 40% savings
# 3-year reserved instance: 60% savings
```

**3. Auto Scaling Optimization**
```hcl
# Reduce min instances during low traffic
asg_min_size = 1  # Instead of 3 (saves ~$17/month)
```

**4. RDS Optimization**
```hcl
# Single-AZ for dev (not recommended for production)
db_multi_az = false  # Saves ~$15/month

# Smaller instance class
db_instance_class = "db.t3.micro"  # Already optimized
```

**5. S3 Lifecycle Policies**
```hcl
# Already configured: Move to Standard-IA after 30 days
# Additional: Delete objects after 90 days if not needed
```

**6. CloudWatch Log Retention**
```hcl
# Reduce retention period
retention_in_days = 3  # Instead of 7 (minimal savings)
```

---

### **Free Tier Eligible Services**

- **Lambda** - 1M requests/month free
- **CloudWatch** - 10 custom metrics, 5GB logs free
- **DynamoDB** - 25GB storage, 25 read/write capacity units
- **SNS** - 1,000 email deliveries free
- **SES** - 62,000 emails/month (if sending from EC2)

---

## 📚 Additional Resources

### **Related Repositories**
- **Application Code:** [webapp-fork](https://github.com/RitiMoradiyaOrg/webapp-fork)
- **Serverless Functions:** [serverless-fork](https://github.com/RitiMoradiyaOrg/serverless-fork)

### **Documentation**
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Auto Scaling Best Practices](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-instance-monitoring.html)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

## 📄 License

MIT License - Academic project for CSYE 6225

---

## 👤 Author

**Student Project**
- University: Northeastern University
- Course: CSYE 6225 - Network Structures and Cloud Computing

---

## 🎓 Course Information

**Course:** CSYE 6225 - Network Structures and Cloud Computing  
**Institution:** Northeastern University  

This infrastructure represents the culmination of progressive assignments, demonstrating mastery of:
- Infrastructure as Code with Terraform
- AWS multi-service integration (15+ services)
- High availability and fault tolerance
- Enterprise security practices
- Auto-scaling and load balancing
- Zero-downtime deployment strategies
- Comprehensive monitoring and logging

---

## 🌟 Key Features Summary

✅ **95+ AWS Resources** managed by Terraform  
✅ **Multi-AZ High Availability** across 3 availability zones  
✅ **Auto-Scaling Infrastructure** (3-5 instances) with target tracking  
✅ **Zero-Downtime Deployments** via automated instance refresh  
✅ **Enterprise Security** - 4 KMS keys, 90-day rotation, Secrets Manager  
✅ **Comprehensive Monitoring** - Segregated CloudWatch logs, custom metrics  
✅ **Serverless Integration** - Lambda email verification workflow  
✅ **SSL/TLS Encryption** - ACM certificates with auto-renewal  
✅ **Multi-Environment Support** - DEV and DEMO configurations  
✅ **Complete Automation** - CI/CD integrated infrastructure updates

**Production-ready infrastructure showcasing enterprise-grade cloud architecture!** 🎉