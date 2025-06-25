output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID of the VPC"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "IDs of the public subnets"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "IDs of the private subnets"
}

output "natgw_id" {
  value       = module.natgw.natgw_id
  description = "ID of the NAT Gateway"
}

output "bastion_instance_id" {
  value       = module.bastion.bastion_id
  description = "ID of the Bastion host"
}

output "bastion_public_ip" {
  value       = module.bastion.bastion_public_ip
  description = "Public IP of the Bastion host"
}

output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "DNS name of the Application Load Balancer"
}

output "alb_arn" {
  value       = module.alb.alb_arn
  description = "ARN of the Application Load Balancer"
}

output "alb_listener_arn" {
  value       = module.alb.alb_listener_arn
  description = "ARN of the ALB Listener"
}

output "asg_id" {
  value       = module.asg.asg_id
  description = "ID of the Auto Scaling Group"
}

output "asg_launch_template_id" {
  value       = module.asg.launch_template_id
  description = "ID of the Launch Template for ASG"
}
