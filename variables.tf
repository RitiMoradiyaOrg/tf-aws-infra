variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Name tag for VPC"
  type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "devv"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8080
}

variable "subnet_count" {
  description = "Number of subnets to create (both public and private). If null, uses all available AZs"
  type        = number
  default     = null
}

variable "ec2_key_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
}

# RDS Variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine" {
  description = "Database engine (postgres, mysql, or mariadb)"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "14.15"
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "csye6225"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "csye6225"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS instance in GB"
  type        = number
  default     = 20
}

variable "db_parameter_family" {
  description = "Database parameter group family"
  type        = string
  default     = "postgres14"
}

#######################################
# ASSIGNMENT 08 VARIABLES
#######################################

variable "domain_name" {
  description = "Root domain name (e.g., ritimoradiya.me)"
  type        = string
}

variable "subdomain" {
  description = "Subdomain prefix (e.g., dev or demo)"
  type        = string
}

# Auto Scaling Group Variables
variable "asg_min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 3
}

variable "asg_max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 5
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 1
}

variable "asg_cooldown" {
  description = "Cooldown period for ASG in seconds"
  type        = number
  default     = 60
}

# Auto Scaling Policy Variables
variable "scale_up_cpu_threshold" {
  description = "CPU threshold percentage to trigger scale up"
  type        = number
  default     = 5
}

variable "scale_down_cpu_threshold" {
  description = "CPU threshold percentage to trigger scale down"
  type        = number
  default     = 3
}

# Health Check Variables
variable "health_check_path" {
  description = "Path for ALB health check"
  type        = string
  default     = "/healthz"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive health checks successes required"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive health check failures required"
  type        = number
  default     = 2
}

#######################################
# ASSIGNMENT 09 VARIABLES
# Email Verification System
#######################################

# SNS Topic
variable "sns_topic_name" {
  description = "Name of the SNS topic for user registration notifications"
  type        = string
  default     = "user-registration-topic"
}

# DynamoDB Table
variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for email tracking"
  type        = string
  default     = "EmailVerificationTracking"
}

# Lambda Function
variable "lambda_function_name" {
  description = "Name of the Lambda function for email verification"
  type        = string
  default     = "emailVerificationLambda"
}

variable "lambda_runtime" {
  description = "Runtime for Lambda function"
  type        = string
  default     = "nodejs18.x"
}

variable "lambda_handler" {
  description = "Handler for Lambda function"
  type        = string
  default     = "index.handler"
}

variable "lambda_zip_path" {
  description = "Path to Lambda function ZIP file"
  type        = string
  default     = "./lambda/email-verification.zip"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 60
}

variable "lambda_memory" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 256
}

# SES Configuration
variable "ses_from_email" {
  description = "Email address to send verification emails from"
  type        = string
}

variable "ses_domain" {
  description = "Domain for SES email sending"
  type        = string
}