#######################################
# SECRETS MANAGER FOR DB PASSWORD
#######################################

# Generate random password for RDS
resource "random_password" "db_password" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}:?"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

# Store DB password in Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.vpc_name}-db-password-${var.subdomain}-v2"
  description             = "RDS database password for ${var.subdomain} environment"
  kms_key_id              = aws_kms_key.secrets.id
  recovery_window_in_days = 0 # ✅ CHANGED - Force delete immediately (no recovery window)

  tags = merge(local.common_tags, {
    Name       = "${var.vpc_name}-db-password"
    Purpose    = "RDS password storage"
    Assignment = "09"
  })
}

# Store the password value
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}