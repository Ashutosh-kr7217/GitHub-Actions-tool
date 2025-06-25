variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "secure-app-infra"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner of the infrastructure"
  type        = string
  default     = "DevOps Team"
}

variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default     = {}
}

# VPC Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = map(string)
  default = {
    "ap-south-1a" = "10.0.1.0/24"
    "ap-south-1b" = "10.0.2.0/24"
  }
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = map(string)
  default = {
    "ap-south-1a" = "10.0.10.0/24"
    "ap-south-1b" = "10.0.11.0/24"
  }
}

# Security Variables
variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH to bastion"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Key Variables
variable "bastion_key_name" {
  description = "Name of SSH key for bastion host"
  type        = string
  default     = "DevPro-HP-key"
}

variable "app_key_name" {
  description = "Name of SSH key for application instances"
  type        = string
  default     = "DevPro-HP-key"
}

variable "bastion_instance_type" {
  description = "EC2 instance type for bastion host"
  type        = string
  default     = "t3.micro"
}

variable "app_instance_type" {
  description = "EC2 instance type for application servers"
  type        = string
  default     = "t3.small"
}

# Scaling Variables
variable "min_size" {
  description = "Minimum size of ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum size of ASG"
  type        = number
  default     = 10
}

variable "desired_capacity" {
  description = "Desired capacity of ASG"
  type        = number
  default     = 2
}

# Optional Variables
variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for HTTPS listener"
  type        = string
  default     = ""
}

variable "enable_alb_logs" {
  description = "Whether to enable ALB access logs"
  type        = bool
  default     = false
}

variable "alb_logs_bucket" {
  description = "S3 bucket name for ALB access logs"
  type        = string
  default     = ""
}

# App Secrets
variable "app_secrets" {
  description = "Application secrets to store in AWS Secrets Manager"
  type        = map(string)
  default = {
    "DB_USERNAME" = "appuser"
    "DB_PASSWORD" = "ExamplePassword123!"  # Don't use this in production, use secrets management
    "API_KEY"     = "example-api-key"
  }
  sensitive = true
}

variable "app_ami_id" {
  description = "AMI ID for application servers (built by CI pipeline)"
  type        = string
  default     = ""  # Will use the Amazon Linux 2 AMI if not provided
}
