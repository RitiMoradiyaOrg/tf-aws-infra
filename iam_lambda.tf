#######################################
# IAM ROLE AND POLICIES FOR LAMBDA
# Assignment 09
#######################################

# IAM Role for Lambda Function
resource "aws_iam_role" "lambda_role" {
  name = "${var.lambda_function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.lambda_function_name}-role"
    Environment = var.subdomain
    Purpose     = "Lambda execution role"
    Assignment  = "09"
  }
}

# Policy: CloudWatch Logs (for Lambda logging)
resource "aws_iam_role_policy" "lambda_cloudwatch_policy" {
  name = "${var.lambda_function_name}-cloudwatch-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:*:*"
      }
    ]
  })
}

# Policy: DynamoDB Access (read and write for email tracking)
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "${var.lambda_function_name}-dynamodb-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.email_tracking.arn
      }
    ]
  })
}

# Policy: SES Access (send emails)
resource "aws_iam_role_policy" "lambda_ses_policy" {
  name = "${var.lambda_function_name}-ses-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy: SNS Access (receive messages)
resource "aws_iam_role_policy" "lambda_sns_policy" {
  name = "${var.lambda_function_name}-sns-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Subscribe",
          "sns:Receive"
        ]
        Resource = aws_sns_topic.user_registration.arn
      }
    ]
  })
}