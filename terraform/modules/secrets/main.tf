# AWS Secrets Manager Secret
resource "aws_secretsmanager_secret" "app_secrets" {
  name                    = "${var.project_name}/${var.environment}/app"
  description             = "Application secrets for ${var.environment} environment"
  recovery_window_in_days = var.recovery_window_in_days
  
  tags = var.tags
  
  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      tags,
      tags_all,  # Added tags_all here
      recovery_window_in_days
    ]
    create_before_destroy = false
  }
}

# AWS Secrets Manager Secret Version
resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id     = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode(var.app_secrets)
}

# IAM Policy for EC2 to access Secrets
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.project_name}-${var.environment}-secrets-access"
  description = "Policy to access application secrets"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.app_secrets.arn
      }
    ]
  })
  
  tags = var.tags

  lifecycle {
    prevent_destroy = false
    ignore_changes = [tags, tags_all]  # Added tags_all here
  }
}

# Resource Policy for the Secret
resource "aws_secretsmanager_secret_policy" "app_secrets_policy" {
  count      = var.attach_resource_policy ? 1 : 0
  secret_arn = aws_secretsmanager_secret.app_secrets.arn
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          AWS = var.allowed_account_ids
        }
        Action   = "secretsmanager:GetSecretValue"
        Resource = "*"
      }
    ]
  })
}

# IAM Role for EC2 to access Secrets
resource "aws_iam_role" "ec2_secrets_role" {
  name = "${var.project_name}-${var.environment}-ec2-secrets-role"
  
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
  
  tags = var.tags
  
  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      tags,
      tags_all,  # Added tags_all here
      assume_role_policy
    ]
    create_before_destroy = false
  }
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_secrets_role.name

  lifecycle {
    prevent_destroy = false
    ignore_changes = [tags, tags_all]  # Added tags_all here
  }
}

# Attach Secrets Access Policy to Role
resource "aws_iam_role_policy_attachment" "secrets_attachment" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}