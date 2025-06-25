# Dev Environment Terraform Setup

This directory contains the Terraform configuration for the `dev` environment.

## Modules Used

- **VPC:** Provisions VPC, public & private subnets, and route tables.
- **NAT Gateway:** Provides outbound internet access for private subnets.
- **Bastion:** Deploys a bastion host in a public subnet for SSH access.
- **ALB:** Sets up an Application Load Balancer with target group and listener.
- **ASG:** Configures an Auto Scaling Group with Launch Template for app servers.

## Usage

1. **Configure Variables**

   Edit `variables.tf` and provide values for:
   - `admin_cidr` (your IP for SSH access)
   - `ami` (AMI ID to use for app servers)
   - `key_name` (EC2 SSH Key Pair name)

2. **Initialize Terraform**

   ```sh
   terraform init
   ```

3. **Plan**

   ```sh
   terraform plan
   ```

4. **Apply**

   ```sh
   terraform apply
   ```

## Outputs

After apply, key outputs will include:
- VPC ID, subnet IDs
- NAT Gateway ID
- Bastion instance details (ID, public IP)
- ALB DNS name & ARNs
- ASG and Launch Template IDs

## Notes

- Replace any placeholder values (like AMI IDs or key names) before applying.
- Adjust subnet CIDRs, instance types, and scaling options as needed for your use case.
- For production, use remote state (`backend.tf`) and secrets management.
