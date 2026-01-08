output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "application_security_group_id" {
  description = "ID of application security group"
  value       = aws_security_group.application.id
}

output "load_balancer_security_group_id" {
  description = "ID of load balancer security group"
  value       = aws_security_group.load_balancer.id
}

output "load_balancer_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.webapp.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.webapp.zone_id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.webapp.name
}

output "target_group_arn" {
  description = "ARN of the Target Group"
  value       = aws_lb_target_group.webapp.arn
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${var.subdomain}.${var.domain_name}"
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "s3_bucket_name" {
  description = "S3 bucket name for images"
  value       = aws_s3_bucket.images.id
}

#######################################
# ASSIGNMENT 09 OUTPUTS
#######################################

output "sns_topic_arn" {
  description = "ARN of the SNS topic for user registration notifications"
  value       = aws_sns_topic.user_registration.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic"
  value       = aws_sns_topic.user_registration.name
}

output "lambda_function_name" {
  description = "Name of the Lambda function for email verification"
  value       = aws_lambda_function.email_verification.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.email_verification.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for email tracking"
  value       = aws_dynamodb_table.email_tracking.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.email_tracking.arn
}