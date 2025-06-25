variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for launch template (defaults to latest Amazon Linux 2 if empty)"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Name of SSH key pair for EC2 instances"
  type        = string
}

variable "instance_profile_name" {
  description = "Name of IAM instance profile for EC2 instances"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs for EC2 instances"
  type        = list(string)
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Type of root volume"
  type        = string
  default     = "gp3"
}

variable "user_data" {
  description = "User data script for EC2 instances"
  type        = string
  default     = ""
}

variable "detailed_monitoring" {
  description = "Whether to enable detailed monitoring"
  type        = bool
  default     = true
}

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

variable "subnet_ids" {
  description = "List of subnet IDs for ASG"
  type        = list(string)
}

variable "health_check_type" {
  description = "Health check type (EC2 or ELB)"
  type        = string
  default     = "ELB"
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds"
  type        = number
  default     = 300
}

variable "target_group_arns" {
  description = "List of target group ARNs for ALB"
  type        = list(string)
}

variable "scale_out_cooldown" {
  description = "Cooldown period for scale-out in seconds"
  type        = number
  default     = 300
}

variable "scale_in_cooldown" {
  description = "Cooldown period for scale-in in seconds"
  type        = number
  default     = 300
}

variable "scale_out_cpu_threshold" {
  description = "CPU threshold for scaling out"
  type        = number
  default     = 70
}

variable "scale_in_cpu_threshold" {
  description = "CPU threshold for scaling in"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
