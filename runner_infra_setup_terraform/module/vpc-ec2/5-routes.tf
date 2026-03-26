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
