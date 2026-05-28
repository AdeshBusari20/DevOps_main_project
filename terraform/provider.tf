# ==============================================
# Terraform Provider Configuration
# ==============================================
# Configures the AWS provider for ap-south-1 (Mumbai)
# ==============================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state storage (recommended for teams)
  # Uncomment and configure for production use:
  # backend "s3" {
  #   bucket         = "expense-tracker-terraform-state"
  #   key            = "prod/terraform.tfstate"
  #   region         = "ap-south-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "AI-Expense-Tracker"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
