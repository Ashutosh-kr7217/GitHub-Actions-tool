aws_region   = "ap-south-1"
project_name = "secure-app-infra"
environment  = "dev"
owner        = "DevOps Team"

default_tags = {
  "Team"       = "DevOps"
  "Department" = "IT"
}

vpc_cidr = "10.0.0.0/16"
public_subnets = {
  "ap-south-1a" = "10.0.1.0/24"
  "ap-south-1b" = "10.0.2.0/24"
}
private_subnets = {
  "ap-south-1a" = "10.0.10.0/24"
  "ap-south-1b" = "10.0.11.0/24"
}

ssh_cidr_blocks       = ["0.0.0.0/0"]
bastion_key_name      = "GitHub-Actions"
bastion_instance_type = "t3.small"

app_key_name       = "GitHub-Actions"
app_instance_type  = "t3.small"
#app_instance_count = 2
