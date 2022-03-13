resource "aws_instance" "myec2" {
  ami                    = "ami-0742b4e673072066f"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.TerraformEC2_security.name]
  
  tags = {
    Name = "Terraform-Ec2"
  }
}
