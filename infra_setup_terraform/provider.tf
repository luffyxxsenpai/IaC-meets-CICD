terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.97.0"
    }
  }
  backend "s3" {
    bucket       = "luffysenpaiterraformbucket"
    key          = "terraform-infra-setup.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
  }
}

provider "aws" {
  region  = "ap-south-1"
}
