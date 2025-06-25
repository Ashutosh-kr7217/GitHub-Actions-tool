# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id
  
  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "HTTP"
  }
  
  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "HTTPS"
  }
  
  # Outbound access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-alb-sg"
    }
  )
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids
  
  enable_deletion_protection = var.enable_deletion_protection
  
  access_logs {
    bucket  = var.access_logs_bucket
    prefix  = "${var.project_name}-${var.environment}-alb-logs"
    enabled = var.enable_access_logs && var.access_logs_bucket != ""
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-alb"
    }
  )
}

# Target Group
resource "aws_lb_target_group" "main" {
  name        = "${var.project_name}-${var.environment}-tg"
  port        = var.target_port
  protocol    = var.target_protocol
  vpc_id      = var.vpc_id
  target_type = var.target_type
  
  health_check {
    enabled             = true
    path                = var.health_check_path
    port                = var.health_check_port
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 5  # More tolerance for failures
    timeout             = 10  # Longer timeout
    interval            = 30  # Longer interval
    matcher             = "200"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = var.stickiness_enabled
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-tg"
    }
  )
  
  lifecycle {
    create_before_destroy = true
  }
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type = var.ssl_certificate_arn != "" ? "redirect" : "forward"
    
    dynamic "redirect" {
      for_each = var.ssl_certificate_arn != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    
    dynamic "forward" {
      for_each = var.ssl_certificate_arn == "" ? [1] : []
      content {
        target_group {
          arn = aws_lb_target_group.main.arn
        }
      }
    }
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-http-listener"
    }
  )
}

# HTTPS Listener (conditional)
resource "aws_lb_listener" "https" {
  count             = var.ssl_certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.ssl_certificate_arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-https-listener"
    }
  )
}