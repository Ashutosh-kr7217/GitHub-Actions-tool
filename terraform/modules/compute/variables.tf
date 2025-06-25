variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where instances will be deployed"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for instances"
  type        = list(string)
}

variable "app_key_name" {
  description = "Name of SSH key for application instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for application servers"
  type        = string
  default     = "t3.small"
}

variable "instance_count" {
  description = "Number of application instances"
  type        = number
  default     = 2
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Type of the root volume"
  type        = string
  default     = "gp3"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}