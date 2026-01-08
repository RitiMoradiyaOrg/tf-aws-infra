#######################################
# LAMBDA FUNCTION FOR EMAIL VERIFICATION
# Assignment 09
#######################################

# Lambda Function
resource "aws_lambda_function" "email_verification" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory

  # The deployment package (zip file with your code)
  filename         = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)

  # Environment variables for Lambda
  environment {
    variables = {
      DOMAIN         = "${var.subdomain}.${var.domain_name}"
      SES_FROM_EMAIL = var.ses_from_email
      AWS_REGION     = var.region
      DYNAMODB_TABLE = aws_dynamodb_table.email_tracking.name
      SNS_TOPIC_ARN  = aws_sns_topic.user_registration.arn
    }
  }

  tags = {
    Name        = var.lambda_function_name
    Environment = var.subdomain
    Purpose     = "Email verification"
    Assignment  = "09"
  }

  # Ensure IAM role is created before Lambda
  depends_on = [
    aws_iam_role.lambda_role,
    aws_iam_role_policy.lambda_cloudwatch_policy,
    aws_iam_role_policy.lambda_dynamodb_policy,
    aws_iam_role_policy.lambda_ses_policy,
    aws_iam_role_policy.lambda_sns_policy
  ]
}

# Lambda Permission - Allow SNS to invoke Lambda
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.email_verification.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.user_registration.arn
}

# CloudWatch Log Group for Lambda (with retention)
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14

  tags = {
    Name        = "${var.lambda_function_name}-logs"
    Environment = var.subdomain
    Assignment  = "09"
  }
}