resource "aws_instance" "myec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.TerraformEC2_security.id]
  subnet_id              = aws_subnet.public[0].id

  tags = {
    Name = "Terraform-Ec2"
  }
}
