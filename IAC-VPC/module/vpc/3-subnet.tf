resource "aws_subnet" "public1_subnet" {
  availability_zone       = var.zone1
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public1_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env}-public1-subnet"
  }
  depends_on = [aws_vpc.main]
}

resource "aws_subnet" "public2_subnet" {
  availability_zone       = var.zone2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public2_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env}-public2-subnet"
  }

}

resource "aws_subnet" "private1_subnet" {
  availability_zone       = var.zone1
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private1_subnet_cidr
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.env}-private-subnet"
  }
}

resource "aws_subnet" "private2_subnet" {
  availability_zone       = var.zone2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private2_subnet_cidr
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.env}-private2-subnet"
  }
}

