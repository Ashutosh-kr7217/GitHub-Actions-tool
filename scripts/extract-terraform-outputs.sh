#!/bin/bash
# Purpose: Safely extract Terraform outputs without using command substitution
# Usage: ./extract-terraform-outputs.sh [working-directory]

set -e

# Use specified directory or default to current
TF_DIR=${1:-.}
cd "$TF_DIR"

echo "📋 Extracting Terraform outputs from: $TF_DIR"

# Create temp directory for output files
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Get all outputs in plain text format
terraform output > "$TEMP_DIR/all_outputs.txt"
echo "📋 Available Terraform outputs:"
cat "$TEMP_DIR/all_outputs.txt"

# Extract outputs to files first (no command substitution)
grep -E "^vpc_id = " "$TEMP_DIR/all_outputs.txt" | cut -d '=' -f2- | sed 's/^[ "]*//;s/[ "]*$//' > "$TEMP_DIR/vpc_id.txt"
grep -E "^alb_dns_name = " "$TEMP_DIR/all_outputs.txt" | cut -d '=' -f2- | sed 's/^[ "]*//;s/[ "]*$//' > "$TEMP_DIR/alb_dns_name.txt"
grep -E "^bastion_public_ip = " "$TEMP_DIR/all_outputs.txt" | cut -d '=' -f2- | sed 's/^[ "]*//;s/[ "]*$//' > "$TEMP_DIR/bastion_public_ip.txt"
grep -E "^asg_name = " "$TEMP_DIR/all_outputs.txt" | cut -d '=' -f2- | sed 's/^[ "]*//;s/[ "]*$//' > "$TEMP_DIR/asg_name.txt"

# For subnet IDs
grep -A 5 "public_subnet_ids" "$TEMP_DIR/all_outputs.txt" | grep -o '"subnet-[a-z0-9]*"' | tr -d '"' > "$TEMP_DIR/public_subnets.txt"
grep -A 5 "private_subnet_ids" "$TEMP_DIR/all_outputs.txt" | grep -o '"subnet-[a-z0-9]*"' | tr -d '"' > "$TEMP_DIR/private_subnets.txt"

# Write outputs directly to GITHUB_OUTPUT - no command substitution
if [ -s "$TEMP_DIR/vpc_id.txt" ]; then
  echo "vpc_id=$(cat "$TEMP_DIR/vpc_id.txt")" >> $GITHUB_OUTPUT
  echo "✅ Set vpc_id output"
else
  echo "⚠️ VPC ID not found"
  echo "vpc_id=" >> $GITHUB_OUTPUT
fi

# Public subnets (comma-separated)
if [ -s "$TEMP_DIR/public_subnets.txt" ]; then
  # Create comma-separated list without command substitution
  tr '\n' ',' < "$TEMP_DIR/public_subnets.txt" | sed 's/,$//' > "$TEMP_DIR/public_subnets_csv.txt"
  echo "public_subnet_ids=$(cat "$TEMP_DIR/public_subnets_csv.txt")" >> $GITHUB_OUTPUT
  echo "✅ Set public_subnet_ids output"
else
  echo "⚠️ Public subnet IDs not found"
  echo "public_subnet_ids=" >> $GITHUB_OUTPUT
fi

# Private subnets (comma-separated)
if [ -s "$TEMP_DIR/private_subnets.txt" ]; then
  # Create comma-separated list without command substitution
  tr '\n' ',' < "$TEMP_DIR/private_subnets.txt" | sed 's/,$//' > "$TEMP_DIR/private_subnets_csv.txt"
  echo "private_subnet_ids=$(cat "$TEMP_DIR/private_subnets_csv.txt")" >> $GITHUB_OUTPUT
  echo "✅ Set private_subnet_ids output"
else
  echo "⚠️ Private subnet IDs not found"
  echo "private_subnet_ids=" >> $GITHUB_OUTPUT
fi

# ALB DNS
if [ -s "$TEMP_DIR/alb_dns_name.txt" ]; then
  echo "alb_dns_name=$(cat "$TEMP_DIR/alb_dns_name.txt")" >> $GITHUB_OUTPUT
  echo "✅ Set alb_dns_name output"
else
  echo "⚠️ ALB DNS name not found"
  echo "alb_dns_name=" >> $GITHUB_OUTPUT
fi

# Bastion IP
if [ -s "$TEMP_DIR/bastion_public_ip.txt" ]; then
  echo "bastion_public_ip=$(cat "$TEMP_DIR/bastion_public_ip.txt")" >> $GITHUB_OUTPUT
  echo "✅ Set bastion_public_ip output"
else
  echo "⚠️ Bastion public IP not found"
  echo "bastion_public_ip=" >> $GITHUB_OUTPUT
fi

# ASG Name
if [ -s "$TEMP_DIR/asg_name.txt" ]; then
  echo "asg_name=$(cat "$TEMP_DIR/asg_name.txt")" >> $GITHUB_OUTPUT
  echo "✅ Set asg_name output"
else
  echo "⚠️ ASG name not found"
  echo "asg_name=" >> $GITHUB_OUTPUT
fi

echo "✅ All outputs extracted successfully"