output "secrets_arn" {
  description = "ARN of the secret in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.app_secrets.arn
}

output "secrets_name" {
  description = "Name of the secret in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.app_secrets.name
}

output "policy_arn" {
  description = "ARN of the IAM policy for accessing secrets"
  value       = aws_iam_policy.secrets_access.arn
}

output "ec2_role_arn" {
  description = "ARN of the IAM role for EC2 instances"
  value       = aws_iam_role.ec2_secrets_role.arn
}

output "ec2_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}