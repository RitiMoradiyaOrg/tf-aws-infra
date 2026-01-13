terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

# Data source to get available AZs dynamically
data "aws_availability_zones" "available" {
  state = "available"
}

# Local values for dynamic configuration
locals {
  # Get available AZs in the region
  available_azs = data.aws_availability_zones.available.names
  az_count      = length(local.available_azs)

  # Calculate subnet count (use variable or default to AZ count)
  actual_subnet_count = var.subnet_count != null ? var.subnet_count : local.az_count

  # Calculate subnet bits for CIDR
  subnet_bits = ceil(log(local.actual_subnet_count * 2, 2))

  # Get unique public subnets (one per AZ) for Load Balancer
  # ALB requires at least 2 AZs and can't have multiple subnets in same AZ
  unique_public_subnets = [
    for idx, subnet in aws_subnet.public : subnet.id
    if index(
      [for s in aws_subnet.public : s.availability_zone],
      subnet.availability_zone
    ) == idx
  ]

  # Common tags
  common_tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Project     = "CSYE6225"
  }

  # Name prefix
  name_prefix = var.vpc_name
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = var.vpc_name
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-igw"
  })
}

#######################################
# NAT GATEWAY (FOR PRIVATE SUBNET INTERNET ACCESS)
#######################################

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-nat-eip"
  })

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway (in first public subnet)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-nat-gateway"
  })

  depends_on = [aws_internet_gateway.main]
}

# Public Subnets with Ultra-Dynamic Distribution
resource "aws_subnet" "public" {
  count                   = local.actual_subnet_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, local.subnet_bits, count.index)
  availability_zone       = local.available_azs[count.index % local.az_count]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-public-subnet-${count.index + 1}"
    Type    = "subnet"
    SubType = "public"
    AZ      = local.available_azs[count.index % local.az_count]
    Purpose = "public-workloads"
  })
}

# Private Subnets with Ultra-Dynamic Distribution
resource "aws_subnet" "private" {
  count             = local.actual_subnet_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, local.subnet_bits, count.index + local.actual_subnet_count)
  availability_zone = local.available_azs[count.index % local.az_count]

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-private-subnet-${count.index + 1}"
    Type    = "subnet"
    SubType = "private"
    AZ      = local.available_azs[count.index % local.az_count]
    Purpose = "database-workloads"
  })
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-public-rt"
  })
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-private-rt"
  })
}

# Public Route
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Private Route - Internet access through NAT Gateway
resource "aws_route" "private_internet_access" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

# Public Route Table Associations
resource "aws_route_table_association" "public" {
  count          = local.actual_subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table Associations
resource "aws_route_table_association" "private" {
  count          = local.actual_subnet_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

#######################################
# SECURITY GROUPS
#######################################

# Load Balancer Security Group
resource "aws_security_group" "load_balancer" {
  name        = "${var.vpc_name}-load-balancer-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP from anywhere
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS from anywhere
  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-load-balancer-sg"
  })
}

# Application Security Group
resource "aws_security_group" "application" {
  name        = "${var.vpc_name}-application-sg"
  description = "Security group for web application"
  vpc_id      = aws_vpc.main.id

  # SSH access from anywhere (for debugging)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Application port - ONLY from Load Balancer Security Group
  ingress {
    description     = "Application from Load Balancer"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer.id]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-application-sg"
  })
}

# Database Security Group
resource "aws_security_group" "database" {
  name        = "${var.vpc_name}-database-sg"
  description = "Security group for RDS database"
  vpc_id      = aws_vpc.main.id

  # Allow PostgreSQL traffic from application security group ONLY
  ingress {
    description     = "PostgreSQL from application"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-database-sg"
  })
}

#######################################
# RDS RESOURCES
#######################################

# Random UUID for S3 Bucket Name (Globally Unique)
resource "random_uuid" "s3_bucket" {}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name        = "${var.vpc_name}-db-subnet-group"
  description = "Database subnet group for RDS"
  subnet_ids  = aws_subnet.private[*].id

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-db-subnet-group"
  })
}

# RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  name        = "${var.vpc_name}-db-parameter-group"
  family      = var.db_parameter_family
  description = "Custom parameter group for ${var.db_engine}"

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-db-parameter-group"
  })
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier     = "csye6225"
  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp2"
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result
  port     = var.db_port

  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]

  publicly_accessible = false
  multi_az            = false

  skip_final_snapshot = true

  tags = merge(local.common_tags, {
    Name = "csye6225-rds-instance"
  })
}

#######################################
# S3 RESOURCES
#######################################

# S3 Bucket for Image Storage (Using UUID)
resource "aws_s3_bucket" "images" {
  bucket        = random_uuid.s3_bucket.result
  force_destroy = true

  tags = merge(local.common_tags, {
    Name    = "${var.vpc_name}-images-${random_uuid.s3_bucket.result}"
    Type    = "s3-bucket"
    Purpose = "image-storage"
  })
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

# S3 Bucket Public Access Block (Keep it Private)
resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Lifecycle Policy
resource "aws_s3_bucket_lifecycle_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

#######################################
# IAM RESOURCES
#######################################

# IAM Role for EC2 Instance
resource "aws_iam_role" "ec2_role" {
  name = "${var.vpc_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-ec2-role"
  })
}

# IAM Policy for S3 Access
resource "aws_iam_role_policy" "s3_policy" {
  name = "${var.vpc_name}-s3-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.images.arn,
          "${aws_s3_bucket.images.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.s3.arn
      }
    ]
  })
}

# IAM Policy for SNS Publish
resource "aws_iam_role_policy" "sns_policy" {
  name = "${var.vpc_name}-sns-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.user_registration.arn
      }
    ]
  })
}

# IAM Policy for Secrets Manager Access
resource "aws_iam_role_policy" "secrets_policy" {
  name = "${var.vpc_name}-secrets-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.db_password.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.secrets.arn
      }
    ]
  })
}

# Attach CloudWatch Agent Policy to EC2 Role
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach SSM Policy to EC2 Role
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.vpc_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-ec2-profile"
  })
}

#######################################
# CLOUDWATCH LOG GROUPS
#######################################

# CloudWatch Log Group for Application Logs
resource "aws_cloudwatch_log_group" "webapp_application" {
  name              = "/csye6225/${var.subdomain}/webapp/application"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-webapp-application-logs"
  })
}

# CloudWatch Log Group for Deployment Logs
resource "aws_cloudwatch_log_group" "webapp_deployment" {
  name              = "/csye6225/${var.subdomain}/webapp/deployment"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-webapp-deployment-logs"
  })
}

#######################################
# AUTO SCALING & LOAD BALANCER
#######################################

# Launch Template
resource "aws_launch_template" "webapp" {
  name          = "${var.vpc_name}-launch-template"
  description   = "Launch template for webapp Auto Scaling Group"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.ec2_key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 25
      volume_type           = "gp2"
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = aws_kms_key.ebs.arn
    }
  }

  network_interfaces {
    associate_public_ip_address = false # ✅ FIXED - Private subnets don't need public IPs
    security_groups             = [aws_security_group.application.id]
    delete_on_termination       = true
  }

  # ✅ USE EXTERNAL user-data.sh - CORRECTED parameter list
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    db_host        = aws_db_instance.main.address
    db_username    = var.db_username
    db_password    = random_password.db_password.result
    db_name        = var.db_name
    db_secret_name = aws_secretsmanager_secret.db_password.name
    s3_bucket      = random_uuid.s3_bucket.result
    sns_topic_arn  = aws_sns_topic.user_registration.arn
    app_port       = var.app_port
    environment    = var.subdomain
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${var.vpc_name}-webapp-instance"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-launch-template"
  })
}

# Target Group for Load Balancer
resource "aws_lb_target_group" "webapp" {
  name     = "${var.vpc_name}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-target-group"
  })
}

# Application Load Balancer
resource "aws_lb" "webapp" {
  name               = "${var.vpc_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer.id]
  subnets            = local.unique_public_subnets

  enable_deletion_protection = false
  enable_http2               = true

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-alb"
  })
}

# HTTPS Listener (Port 443) - Primary
resource "aws_lb_listener" "webapp_https" {
  load_balancer_arn = aws_lb.webapp.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.cert_validation.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp.arn
  }

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-listener-https"
  })
}

# HTTP Listener (Port 80) - Redirect to HTTPS
resource "aws_lb_listener" "webapp_http" {
  load_balancer_arn = aws_lb.webapp.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-listener-http-redirect"
  })
}

# Auto Scaling Group
resource "aws_autoscaling_group" "webapp" {
  name                      = "${var.vpc_name}-asg"
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  default_cooldown          = var.asg_cooldown
  vpc_zone_identifier       = aws_subnet.private[*].id
  target_group_arns         = [aws_lb_target_group.webapp.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.webapp.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.vpc_name}-webapp-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "dev"
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "Terraform"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "CSYE6225"
    propagate_at_launch = true
  }
}

# Scale Up Policy
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.vpc_name}-scale-up-policy"
  autoscaling_group_name = aws_autoscaling_group.webapp.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = var.asg_cooldown
  policy_type            = "SimpleScaling"
}

# Scale Down Policy
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.vpc_name}-scale-down-policy"
  autoscaling_group_name = aws_autoscaling_group.webapp.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = var.asg_cooldown
  policy_type            = "SimpleScaling"
}

# CloudWatch Alarm - Scale Up (CPU > 5%)
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.vpc_name}-high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.scale_up_cpu_threshold
  alarm_description   = "This metric monitors high CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp.name
  }

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-high-cpu-alarm"
  })
}

# CloudWatch Alarm - Scale Down (CPU < 3%)
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.vpc_name}-low-cpu-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.scale_down_cpu_threshold
  alarm_description   = "This metric monitors low CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp.name
  }

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-low-cpu-alarm"
  })
}

#######################################
# ROUTE53 DNS CONFIGURATION
#######################################

# Data source to get the hosted zone for subdomain
data "aws_route53_zone" "subdomain" {
  name         = "${var.subdomain}.${var.domain_name}"
  private_zone = false
}

# A Record pointing to Load Balancer
resource "aws_route53_record" "webapp" {
  zone_id = data.aws_route53_zone.subdomain.zone_id
  name    = "${var.subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.webapp.dns_name
    zone_id                = aws_lb.webapp.zone_id
    evaluate_target_health = true
  }
}