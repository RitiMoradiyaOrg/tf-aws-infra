#######################################
# KMS KEYS FOR ENCRYPTION
# Assignment 09
#######################################

# KMS Key for EC2 EBS Volumes
resource "aws_kms_key" "ebs" {
  description             = "KMS key for EBS volume encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90

  tags = merge(local.common_tags, {
    Name       = "${var.vpc_name}-ebs-kms-key"
    Purpose    = "EBS encryption"
    Assignment = "09"
  })
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/${var.vpc_name}-ebs-key"
  target_key_id = aws_kms_key.ebs.key_id
}

# KMS Key for RDS
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90

  tags = merge(local.common_tags, {
    Name       = "${var.vpc_name}-rds-kms-key"
    Purpose    = "RDS encryption"
    Assignment = "09"
  })
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.vpc_name}-rds-key"
  target_key_id = aws_kms_key.rds.key_id
}

# KMS Key for S3
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90

  tags = merge(local.common_tags, {
    Name       = "${var.vpc_name}-s3-kms-key"
    Purpose    = "S3 encryption"
    Assignment = "09"
  })
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.vpc_name}-s3-key"
  target_key_id = aws_kms_key.s3.key_id
}

# KMS Key for Secrets Manager
resource "aws_kms_key" "secrets" {
  description             = "KMS key for Secrets Manager encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90

  tags = merge(local.common_tags, {
    Name       = "${var.vpc_name}-secrets-kms-key"
    Purpose    = "Secrets encryption"
    Assignment = "09"
  })
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.vpc_name}-secrets-key"
  target_key_id = aws_kms_key.secrets.key_id
}