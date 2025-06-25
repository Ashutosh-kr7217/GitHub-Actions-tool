terraform {
  required_version = "~> 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Ensure these resources actually exist before running pipeline
  backend "s3" {
    bucket         = "tf-state-aws-infra011"
    key            = "secure-app-infra/dev/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}