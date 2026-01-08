#######################################
# SNS TOPIC FOR USER REGISTRATION
# Assignment 09
#######################################

# SNS Topic - User Registration Notifications
resource "aws_sns_topic" "user_registration" {
  name = var.sns_topic_name

  tags = {
    Name        = var.sns_topic_name
    Environment = var.subdomain
    Purpose     = "User registration notifications"
    Assignment  = "09"
  }
}

# SNS Topic Policy - Allow Lambda to subscribe and EC2 to publish
resource "aws_sns_topic_policy" "user_registration_policy" {
  arn = aws_sns_topic.user_registration.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaSubscription"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "SNS:Subscribe",
          "SNS:Receive"
        ]
        Resource = aws_sns_topic.user_registration.arn
      },
      {
        Sid    = "AllowEC2Publish"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ec2_role.arn
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.user_registration.arn
      }
    ]
  })
}

# SNS Topic Subscription - Connect to Lambda
resource "aws_sns_topic_subscription" "user_registration_lambda" {
  topic_arn = aws_sns_topic.user_registration.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.email_verification.arn
}