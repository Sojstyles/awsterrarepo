resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazonlinux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = aws_subnet.public[0].id
  key_name               = "main"

  tags = {
    Name = "${var.environemnt_code}-bastion"
  }
}

resource "aws_eip" "elasticip" {
  vpc = true
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.elasticip.id
}

resource "aws_security_group" "bastion" {
  name        = "${var.environemnt_code}-bastion"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Inbound rules from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block, "37.19.212.68/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environemnt_code}-public"
  }
}
