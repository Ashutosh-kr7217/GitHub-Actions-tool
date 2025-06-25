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

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-${var.environment}-ec2-role"
  
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
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 Instances for Applications
resource "aws_instance" "app" {
  count                  = var.instance_count
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  key_name               = var.app_key_name
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  
  user_data = <<-EOF
              #!/bin/bash
              hostnamectl set-hostname ${var.project_name}-${var.environment}-app-${count.index + 1}
              yum update -y
              yum install -y nginx
              systemctl enable nginx
              systemctl start nginx
              
              # Create a simple index page
              cat > /usr/share/nginx/html/index.html << 'HTMLEOF'
              <!DOCTYPE html>
              <html>
              <head>
                <title>Welcome to ${var.project_name}</title>
                <style>
                  body {
                    width: 35em;
                    margin: 0 auto;
                    font-family: Arial, sans-serif;
                  }
                </style>
              </head>
              <body>
                <h1>Welcome to ${var.project_name}!</h1>
                <p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
                <p>Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
                <p>Environment: ${var.environment}</p>
              </body>
              </html>
              HTMLEOF
              EOF
  
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    delete_on_termination = true
    encrypted             = true
    
    tags = merge(
      var.tags,
      {
        Name = "${var.project_name}-${var.environment}-app-${count.index + 1}-root"
      }
    )
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-app-${count.index + 1}"
    }
  )
  
  lifecycle {
    create_before_destroy = true
  }
}