# Security Group for Bastion Host
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-${var.environment}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id
  
  # SSH access from specified CIDR blocks
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
    description = "SSH access"
  }
  
  # Outbound internet access
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
      Name = "${var.project_name}-${var.environment}-bastion-sg"
    }
  )
}

# Security Group for Application Instances
resource "aws_security_group" "app" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Security group for application instances"
  vpc_id      = var.vpc_id
  
  # SSH access from bastion only
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
    description     = "SSH from bastion"
  }
  
  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }
  
  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }
  
  # Outbound internet access
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
      Name = "${var.project_name}-${var.environment}-app-sg"
    }
  )
}

resource "aws_security_group_rule" "app_from_alb" {
  security_group_id        = aws_security_group.app.id
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = var.alb_security_group_id
  description              = "Allow HTTP traffic from ALB"
}

# Security Group for internal communication
resource "aws_security_group" "internal" {
  name        = "${var.project_name}-${var.environment}-internal-sg"
  description = "Security group for internal communication"
  vpc_id      = var.vpc_id
  
  # Allow all traffic between instances
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-internal-sg"
    }
  )
}

# Network ACLs
resource "aws_network_acl" "main" {
  vpc_id = var.vpc_id
  
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-nacl"
    }
  )
}