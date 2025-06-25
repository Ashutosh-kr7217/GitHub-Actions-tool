variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "admin_cidr" {
  description = "CIDR block for SSH access to bastion"
  type        = string
}

variable "ami" {
  description = "AMI ID for application servers"
  type        = string
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
}