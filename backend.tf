terraform {
  backend "s3" {
    bucket  = "tcp-terraform-state"
    key     = "tcp.tfstate"
    profile = "terraform-dev"
    region  = "us-east-1"
  }
}

data "terraform_remote_state" "tcp" {
  backend = "s3"

  config = {
    bucket  = "tcp-terraform-state"
    key     = "common.tfstate"
    profile = "terraform-tcp"
    region  = "us-east-1"
  }
}
