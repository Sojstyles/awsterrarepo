resource "aws_instance" "jump_box" {
  ami                    = lookup(var.ami_base, "centos-7")
  instance_type          = "t2.medium"
  key_name               = "thirdkey"
  vpc_security_group_ids = [aws_security_group.TerraformEC2_security.id]
  subnet_id              = aws_subnet.private[0].id

  user_data = <<-EOF
                                #!/bin/bash
                                yum -y update
                                EOF
  tags = {
    Name = "${var.environemnt_code}-jumpbox"
  }
}

#creating this new security group for other VM’s in the environment to attach later, such that it can be used to allow SSH from the Jump host to the VM’s in the environment.
resource "aws_security_group" "jump_box_sg" {
  name        = "SG-jumphost"
  description = "Allow SSH from the jump host"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.jump_box.private_ip}/32"]
  }

  tags = {
    Name = "${var.environemnt_code}-SG_jumpbox"
  }
}

#creates a DNS entry for our jump host in Route53
resource "aws_route53_record" "jump_box_dns" {
  zone_id = lookup(var.route53_zone, "id")
  type    = "A"
  ttl     = "300"
  name    = "jump.${lookup(var.route53_zone, "name")}"
  records = ["${aws_instance.jump_box.private_ip}"]
}