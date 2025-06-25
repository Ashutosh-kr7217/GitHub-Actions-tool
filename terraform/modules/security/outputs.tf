output "bastion_sg_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion.id
}

output "app_sg_id" {
  description = "ID of the application security group"
  value       = aws_security_group.app.id
}

output "internal_sg_id" {
  description = "ID of the internal communication security group"
  value       = aws_security_group.internal.id
}

output "nacl_id" {
  description = "ID of the network ACL"
  value       = aws_network_acl.main.id
}