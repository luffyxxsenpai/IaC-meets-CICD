terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.97.0"
    }
  }
  backend "s3" {
    bucket       = "luffysenpaiterraformbucket"
    key          = "terraform-runner-infra.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
    profile      = "super"
  }
}

provider "aws" {
  region  = "ap-south-1"
  profile = "super"
}

