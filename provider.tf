terraform {
  required_version = ">= 1.8.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  profile             = "terraform-dev"
  region              = var.AWS_REGION
  allowed_account_ids = var.ALLOWED_ACCOUNTS_IDS
}
