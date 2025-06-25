# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# ${var.project_name} ${var.environment} Environment Monitoring"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ "AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${var.project_name}-${var.environment}-asg" ]
          ],
          period = 300,
          stat   = "Average",
          region = var.aws_region,
          title  = "EC2 CPU Utilization"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 1
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ "AWS/ApplicationELB", "RequestCount", "LoadBalancer", "app/${var.project_name}-${var.environment}-alb" ]
          ],
          period = 300,
          stat   = "Sum",
          region = var.aws_region,
          title  = "ALB Request Count"
        }
      }
    ]
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/${var.project_name}-${var.environment}-app"
  retention_in_days = 30
  
  tags = var.tags
  
  lifecycle {
    prevent_destroy = false  # Default to false for all environments
    create_before_destroy = true  
    ignore_changes = [
      tags
    ]
  }
}

# CloudWatch Event Rule for ASG State Changes
resource "aws_cloudwatch_event_rule" "ec2_state_change" {
  name        = "${var.project_name}-${var.environment}-ec2-state-change"
  description = "Capture EC2 state changes"
  
  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
    detail = {
      state = ["stopped", "terminated"]
      # Remove instance-id filter for ASG compatibility
    }
  })
  
  tags = var.tags
}

# CloudWatch Alarm for ASG CPU
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-asg-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "This metric monitors ASG CPU utilization"
  
  dimensions = {
    AutoScalingGroupName = "${var.project_name}-${var.environment}-asg"
  }
  
  tags = var.tags
}
