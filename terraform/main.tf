provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = local.project_name
      Environment = local.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
      LastUpdated = formatdate("YYYY-MM-DD", timestamp())
    }
  }
}

locals {
  project_name = var.project_name
  environment  = var.environment

  tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
    LastUpdated = formatdate("YYYY-MM-DD", timestamp())
  }

  app_user_data = <<-EOT
    #!/bin/bash
    # Enable logging
    exec > >(tee /var/log/user-data.log|logger -t user-data) 2>&1
    echo "Starting user data execution at $(date)"
    
    # Set hostname
    hostnamectl set-hostname ${local.project_name}-${local.environment}-app-$(curl -s http://169.254.169.254/latest/meta-data/instance-id | cut -d 'i' -f 2)
    
    # Update and install nginx properly for Amazon Linux 2
    yum update -y
    amazon-linux-extras enable nginx1
    yum install -y nginx curl jq aws-cli
    
    # Create custom index.html - using heredoc to avoid issues with quotes
    mkdir -p /usr/share/nginx/html
    cat > /usr/share/nginx/html/index.html << EOF
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Welcome to ${local.project_name}</title>
        <link rel="stylesheet" href="style.css">
        <meta http-equiv="Content-Security-Policy" content="default-src 'self'">
        <meta http-equiv="X-Content-Type-Options" content="nosniff">
        <meta http-equiv="X-Frame-Options" content="DENY">
    </head>
    <body>
        <div class="container">
            <h1>Welcome to ${local.project_name}!</h1>
            <p><strong>Success!</strong> Your application is working.</p>
            <div class="info">
                <p><strong>Environment:</strong> ${local.environment}</p>
                <p><strong>Instance ID:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
                <p><strong>Availability Zone:</strong> $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
                <p><strong>Server Time:</strong> $(date)</p>
            </div>
        </div>
    </body>
    </html>
    EOF

    # Configure security headers for nginx
    cat > /etc/nginx/conf.d/security-headers.conf << EOF
    # Security headers
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Content-Security-Policy "default-src 'self'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Disable server tokens
    server_tokens off;
    EOF
    
    # Verify nginx config
    nginx -t
    
    # Start and enable nginx
    systemctl enable nginx
    systemctl start nginx
    
    echo "User data execution completed at $(date)"
  EOT
}

module "vpc" {
  source = "./modules/vpc"

  project_name    = local.project_name
  environment     = local.environment
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  tags            = local.tags
}

module "security" {
  source = "./modules/security"

  project_name          = local.project_name
  environment           = local.environment
  vpc_id                = module.vpc.vpc_id
  ssh_cidr_blocks       = var.ssh_cidr_blocks
  alb_security_group_id = module.alb.security_group_id
  tags                  = local.tags
}

module "bastion" {
  source = "./modules/bastion"

  project_name       = local.project_name
  environment        = local.environment
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.security.bastion_sg_id]
  bastion_key_name   = var.bastion_key_name
  instance_type      = var.bastion_instance_type
  tags               = local.tags
}

module "alb" {
  source = "./modules/alb"

  project_name        = local.project_name
  environment         = local.environment
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.public_subnet_ids
  internal            = false
  allowed_cidr_blocks = ["0.0.0.0/0"]
  target_port         = 80
  target_protocol     = "HTTP"
  health_check_path   = "/"
  ssl_certificate_arn = var.ssl_certificate_arn
  enable_access_logs  = var.enable_alb_logs
  access_logs_bucket  = var.alb_logs_bucket
  tags                = local.tags
  
  # Enhanced security settings
  stickiness_enabled = true
  ssl_policy         = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

module "monitoring" {
  source = "./modules/monitoring"

  project_name = local.project_name
  environment  = local.environment
  instance_ids = []  # ASG manages instances
  aws_region   = var.aws_region
  tags         = local.tags
}

module "secrets" {
  source = "./modules/secrets"

  project_name            = local.project_name
  environment             = local.environment
  app_secrets             = var.app_secrets
  recovery_window_in_days = 14  # Longer recovery window for better security
  tags                    = {}
}

module "asg" {
  source = "./modules/asg"

  project_name              = local.project_name
  environment               = local.environment
  ami_id                    = var.app_ami_id != "" ? var.app_ami_id : ""
  instance_type             = var.app_instance_type
  key_name                  = var.app_key_name
  instance_profile_name     = module.secrets.ec2_profile_name
  security_group_ids        = [module.security.app_sg_id]
  subnet_ids                = module.vpc.private_subnet_ids
  target_group_arns         = [module.alb.target_group_arn]
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  health_check_type         = "ELB"
  health_check_grace_period = 300
  root_volume_size          = 30  # Larger volume size
  root_volume_type          = "gp3"  # Use GP3 for better performance
  detailed_monitoring       = true  # Enable detailed CloudWatch monitoring
  user_data                 = local.app_user_data
  tags                      = local.tags
  
  # Enhanced scaling settings
  scale_out_cpu_threshold = 70
  scale_in_cpu_threshold  = 30
  scale_out_cooldown      = 180
  scale_in_cooldown       = 300
}
