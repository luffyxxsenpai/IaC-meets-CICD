module "runner-infra" {
  source = "./module/vpc-ec2"

  env                  = "prod"
  vpc_name             = "github-runner"
  region               = "ap-south-1"
  vpc_cidr             = "10.0.0.0/24"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  public1_subnet_cidr  = "10.0.0.0/25"
  zone1                = "ap-south-1a"
  instance_type        = "t2.micro"
}