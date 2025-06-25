output "instance_ids" {
  description = "IDs of the application instances"
  value       = aws_instance.app[*].id
}

output "private_ips" {
  description = "Private IPs of the application instances"
  value       = aws_instance.app[*].private_ip
}

output "instance_arns" {
  description = "ARNs of the application instances"
  value       = aws_instance.app[*].arn
}

output "ec2_role_arn" {
  description = "ARN of the IAM role for EC2 instances"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}