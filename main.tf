terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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

# Application Security Group
resource "aws_security_group" "application" {
  name        = "${var.vpc_name}-application-sg"
  description = "Security group for web application"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Application port
  ingress {
    description = "Application"
    from_port   = var.app_port
    to_port     = var.app_port
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
    Name = "${var.vpc_name}-application-sg"
  })
}

# EC2 Instance
resource "aws_instance" "webapp" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.application.id]
  key_name               = var.ec2_key_name  # ADDED THIS LINE

  root_block_device {
    volume_size           = 25
    volume_type           = "gp2"
    delete_on_termination = true
  }

  disable_api_termination = false

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-webapp-instance"
  })
}
