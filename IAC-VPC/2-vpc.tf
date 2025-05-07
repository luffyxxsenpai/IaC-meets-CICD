resource "aws_vpc" "main" {
  cidr_block       = local.vpc_cidr
  instance_tenancy = local.instance_tenancy

  enable_dns_hostnames = local.enable_dns_hostnames
  enable_dns_support   = local.enable_dns_support

  tags = {
    Name = "${local.env}-vpc"
  }
}

