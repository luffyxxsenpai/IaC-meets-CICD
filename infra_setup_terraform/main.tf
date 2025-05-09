module "vpc" {
  source = "./module/vpc"

  env                  = "prodddd"
  region               = "ap-south-1"
  vpc_name             = "prod"
  vpc_cidr             = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  public1_subnet_cidr  = "10.0.1.0/24"
  public2_subnet_cidr  = "10.0.2.0/24"
  private1_subnet_cidr = "10.0.3.0/24"
  private2_subnet_cidr = "10.0.4.0/24"
  zone1                = "ap-south-1a"
  zone2                = "ap-south-1b"
}