#######################################
# DYNAMODB TABLE FOR EMAIL TRACKING
# Assignment 09
#######################################

# DynamoDB Table - Email Verification Tracking
resource "aws_dynamodb_table" "email_tracking" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST" # On-demand pricing
  hash_key     = "email"
  range_key    = "sentAt"

  # Primary Key: email (partition key)
  attribute {
    name = "email"
    type = "S" # String
  }

  # Sort Key: sentAt (range key)
  attribute {
    name = "sentAt"
    type = "S" # String (ISO timestamp)
  }

  # TTL - Automatically delete old records after 24 hours
  ttl {
    enabled        = true
    attribute_name = "ttl"
  }

  # Point-in-time recovery for data protection
  point_in_time_recovery {
    enabled = true
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = var.dynamodb_table_name
    Environment = var.subdomain
    Purpose     = "Email verification tracking"
    Assignment  = "09"
  }
}