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
