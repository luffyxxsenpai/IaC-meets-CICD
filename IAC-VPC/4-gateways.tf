resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.env}-${local.vpc_name}-gw"
  }
  depends_on = [aws_vpc.main]
}

resource "aws_eip" "nat1-eip" {
  domain = "vpc"
  tags = {
    Name = "${local.env}-${local.vpc_name}-nat1eip"
  }
  depends_on = [aws_internet_gateway.main]
}

resource "aws_eip" "nat2-eip" {
  domain = "vpc"
  tags = {
    Name = "${local.env}-${local.vpc_name}-nat2-eip"
  }
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "nat1-gw" {
  allocation_id = aws_eip.nat1-eip.allocation_id
  subnet_id     = aws_subnet.public1_subnet.id

  tags = {
    Name = "${local.env}-${local.vpc_name}-nat1"
  }
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "nat2-gw" {
  allocation_id = aws_eip.nat2-eip.allocation_id
  subnet_id     = aws_subnet.public2_subnet.id

  tags = {
    Name = "${local.env}-${local.vpc_name}-nat2"
  }

  depends_on = [aws_internet_gateway.main]

}

