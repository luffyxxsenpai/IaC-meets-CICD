resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-${var.vpc_name}-gw"
  }
  depends_on = [aws_vpc.main]
}
