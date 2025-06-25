terraform {
  backend "s3" {
    bucket         = "tf-state-aws-infra011"   # Changed to match your actual bucket
    key            = "secure-app-infra/dev/terraform.tfstate"  # Changed to match your project
    region         = "ap-south-1"  # Changed to ap-south-1
    dynamodb_table = "terraform-lock"  # Changed to match your lock table
    encrypt        = true
  }
}
