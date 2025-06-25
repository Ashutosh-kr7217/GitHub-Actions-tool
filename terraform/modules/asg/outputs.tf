output "asg_id" {
  description = "ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.id
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.arn
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.app.id
}

output "launch_template_latest_version" {
  description = "Latest version of the Launch Template"
  value       = aws_launch_template.app.latest_version
}

output "scale_out_policy_arn" {
  description = "ARN of the scale-out policy"
  value       = aws_autoscaling_policy.scale_out.arn
}

output "scale_in_policy_arn" {
  description = "ARN of the scale-in policy"
  value       = aws_autoscaling_policy.scale_in.arn
}

output "high_cpu_alarm_arn" {
  description = "ARN of the high CPU alarm"
  value       = aws_cloudwatch_metric_alarm.high_cpu.arn
}

output "low_cpu_alarm_arn" {
  description = "ARN of the low CPU alarm"
  value       = aws_cloudwatch_metric_alarm.low_cpu.arn
}