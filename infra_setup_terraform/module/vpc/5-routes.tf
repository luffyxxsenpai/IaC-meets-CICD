# public route for subnet 1 and subnet 2

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.env}-${var.vpc_name}-public-rt"
  }
}

# assosiate public route to public subnet 1

resource "aws_route_table_association" "public-subnet1-rta" {
  route_table_id = aws_route_table.public-rt.id
  subnet_id      = aws_subnet.public1_subnet.id
}

# assosiate public route to public subnet 1

resource "aws_route_table_association" "public-subnet2-rta" {
  route_table_id = aws_route_table.public-rt.id
  subnet_id      = aws_subnet.public2_subnet.id
}


# route table for private subnet 1 with nat gateway 1

resource "aws_route_table" "private1-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat1-gw.id
  }

  tags = {
    Name = "${var.env}-${var.vpc_name}-private1-rt"
  }
}

# route table for private subnet 2 with nat gateway 2

resource "aws_route_table" "private2-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat2-gw.id
  }

  tags = {
    Name = "${var.env}-${var.vpc_name}-private2-rt"
  }
}

# route table assosiation for private subnet 1
resource "aws_route_table_association" "private1-subnet-1-rta" {
  subnet_id      = aws_subnet.private1_subnet.id
  route_table_id = aws_route_table.private1-rt.id
}

# route table assosiation for private subnet 2
resource "aws_route_table_association" "private2-subnet-2-rta" {
  subnet_id      = aws_subnet.private2_subnet.id
  route_table_id = aws_route_table.private2-rt.id
}
