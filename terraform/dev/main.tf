module "vpc" {
  source        = "../../modules/vpc"
  project_name  = "dev"
  environment   = "dev"
  vpc_cidr      = "10.0.0.0/16"
  public_subnets = {
    "ap-south-1a" = "10.0.1.0/24"  
    "ap-south-1b" = "10.0.2.0/24"  
  }
  private_subnets = {
    "ap-south-1a" = "10.0.101.0/24"  
    "ap-south-1b" = "10.0.102.0/24"  
  }
  tags = {}
}

module "natgw" {
  source      = "../../modules/natgw"  # Ensure this module exists or adjust path
  vpc_id      = module.vpc.vpc_id
  subnet_id   = module.vpc.public_subnet_ids[0]  # Changed public_subnet to subnet_id
}

module "bastion" {
  source            = "../../modules/bastion"
  project_name      = "dev"  # Added project_name
  environment       = "dev"  # Added environment
  subnet_id         = module.vpc.public_subnet_ids[0]  # Changed vpc_id to subnet_id
  security_group_ids = [aws_security_group.bastion.id]  # This needs creation of a security group
  bastion_key_name  = "your-keypair"  # Adjusted parameter name
  tags              = {}
}

resource "aws_security_group" "bastion" {
  name        = "dev-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = module.vpc.vpc_id
  
  # SSH access from specified IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["YOUR_IP/32"]
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
}

module "alb_sg" {
  source = "../../modules/alb"
  vpc_id = module.vpc.vpc_id
  name   = "dev"
}

module "asg_sg" {
  source     = "../../modules/asg"
  vpc_id     = module.vpc.vpc_id
  name       = "dev"
  alb_sg_id  = module.alb_sg.alb_sg_id
}

module "alb" {
  source         = "../../modules/alb"
  project_name   = "dev"  # Added project_name
  environment    = "dev"  # Added environment
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.public_subnet_ids  # Changed public_subnet_ids to subnet_ids
  tags           = {}
}

module "asg" {
  source            = "../../modules/asg"
  name              = "dev"
  ami               = "ami-xxxxxxxx" # Replace with your AMI ID
  instance_type     = "t3.micro"
  key_name          = "your-keypair"
  sg_id             = module.asg_sg.asg_sg_id
  private_subnet_ids= module.vpc.private_subnet_ids
  target_group_arn  = module.alb.alb_target_group_arn
  min_size          = 1
  max_size          = 2
  desired_capacity  = 1
  user_data         = "" # Optional, supply your user data script
}
