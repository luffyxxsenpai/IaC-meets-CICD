# SSH KEY
resource "tls_private_key" "ssh_key_gen" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "aws_key_pair" "ssh-key-pair" {
  key_name   = "${var.vpc_name}-ssh_key"
  public_key = tls_private_key.ssh_key_gen.public_key_openssh
}

resource "local_file" "ssh-pem-local" {
  filename        = "./${aws_key_pair.ssh-key-pair.key_name}"
  content         = tls_private_key.ssh_key_gen.private_key_pem
  file_permission = "0400"
}

# EC2
resource "aws_instance" "runner-ec2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name               = aws_key_pair.ssh-key-pair.key_name
  subnet_id              = aws_subnet.public1_subnet.id

  root_block_device {
    delete_on_termination = true
    encrypted             = false
    volume_size           = 20
    volume_type           = "gp3"
    tags = {
      Name = "root-${var.env}-${var.vpc_name}"
    }
  }

  tags = {
    Name = "selfhosted-runner"
  }

}

output "instance_ip" {
  value = aws_instance.runner-ec2.public_ip
}

