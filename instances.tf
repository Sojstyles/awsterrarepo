resource "aws_instance" "myec2" {
  ami                    = data.aws_ami.amazonlinux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.TerraformEC2_security.id]
  subnet_id              = aws_subnet.public[0].id
  key_name               = "thirdkey"
  user_data              = file("ec2userfile.sh")
  tags = {
    Name = "${var.environemnt_code}-public"
  }
}

resource "aws_eip" "elasticip" {
  vpc = true
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.myec2.id
  allocation_id = aws_eip.elasticip.id
}

resource "aws_security_group" "TerraformEC2_security" {
  name        = "TerraformEC2_security"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Inbound rules from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Inbound rules from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

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
