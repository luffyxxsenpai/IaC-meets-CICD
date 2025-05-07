resource "aws_subnet" "public1_subnet" {
  availability_zone       = local.zone1
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public1_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.env}-public1-subnet"
  }
  depends_on = [aws_vpc.main]
}

resource "aws_subnet" "public2_subnet" {
  availability_zone       = local.zone2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public2_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.env}-public2-subnet"
  }

}

resource "aws_subnet" "private1_subnet" {
  availability_zone       = local.zone1
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.private1_subnet_cidr
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.env}-private-subnet"
  }
}

resource "aws_subnet" "private2_subnet" {
  availability_zone       = local.zone2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.private2_subnet_cidr
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.env}-private2-subnet"
  }
}

