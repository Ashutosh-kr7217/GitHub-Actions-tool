variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "instance_ids" {
  description = "List of EC2 instance IDs to monitor"
  type        = list(string)
}

variable "aws_region" {
  description = "AWS region where resources are deployed"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of SNS topic for notifications (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

