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

# EC2 Instance for Bastion Host
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  key_name               = var.bastion_key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  
  user_data = <<-EOF
              #!/bin/bash
              hostnamectl set-hostname ${var.project_name}-${var.environment}-bastion
              yum update -y
              yum install -y tmux vim htop
              EOF
              
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    delete_on_termination = true
    encrypted             = true
    
    tags = merge(
      var.tags,
      {
        Name = "${var.project_name}-${var.environment}-bastion-root"
      }
    )
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-bastion"
    }
  )
  
  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP for Bastion Host
resource "aws_eip" "bastion" {
  domain   = "vpc"
  instance = aws_instance.bastion.id
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-bastion-eip"
    }
  )
}