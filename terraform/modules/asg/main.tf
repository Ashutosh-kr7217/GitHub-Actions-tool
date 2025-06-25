# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Launch Template for EC2 Instances
resource "aws_launch_template" "app" {
  name          = "${var.project_name}-${var.environment}-launch-template"
  image_id      = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  key_name      = var.key_name
  
  iam_instance_profile {
    name = var.instance_profile_name
  }
  
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = var.security_group_ids
    delete_on_termination       = true
  }
  
  block_device_mappings {
    device_name = "/dev/xvda"
    
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      delete_on_termination = true
      encrypted             = true
    }
  }
  
  user_data = base64encode(<<-EOT
    #!/bin/bash
    hostnamectl set-hostname ${var.project_name}-${var.environment}-app-$(curl -s http://169.254.169.254/latest/meta-data/instance-id | cut -d 'i' -f 2)
    echo "Instance launched from AMI at $(date)" > /var/log/instance-launched.log
    systemctl start nginx
  EOT
  )
  
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  
  monitoring {
    enabled = var.detailed_monitoring
  }
  
  tag_specifications {
    resource_type = "instance"
    
    tags = merge(
      var.tags,
      {
        Name = "${var.project_name}-${var.environment}-app"
      }
    )
  }
  
  tag_specifications {
    resource_type = "volume"
    
    tags = merge(
      var.tags,
      {
        Name = "${var.project_name}-${var.environment}-app-volume"
      }
    )
  }
  
  lifecycle {
    prevent_destroy = false  # Default to false for all environments
    create_before_destroy = true
    ignore_changes = [
      tags
    ]
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  name                      = "${var.project_name}-${var.environment}-asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.subnet_ids
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  target_group_arns         = var.target_group_arns
  
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]
  
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 75
      instance_warmup        = 300
    }
  }
  
  dynamic "tag" {
    for_each = merge(
      var.tags,
      {
        Name = "${var.project_name}-${var.environment}-app"
      }
    )
    
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Scale Out Policy
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.project_name}-${var.environment}-scale-out"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  scaling_adjustment     = 1
  cooldown               = var.scale_out_cooldown
}

# Scale In Policy
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.project_name}-${var.environment}-scale-in"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  scaling_adjustment     = -1
  cooldown               = var.scale_in_cooldown
}

# CloudWatch Alarm for High CPU
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.scale_out_cpu_threshold
  alarm_description   = "Scale out when CPU exceeds threshold"
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

# CloudWatch Alarm for Low CPU
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.scale_in_cpu_threshold
  alarm_description   = "Scale in when CPU falls below threshold"
  alarm_actions       = [aws_autoscaling_policy.scale_in.arn]
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}
