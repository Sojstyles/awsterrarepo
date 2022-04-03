resource "aws_launch_configuration" "server" {

  image_id = data.aws_ami.amazonlinux.id

  instance_type   = "t2.micro"
  key_name        = "thirdkey"
  security_groups = [aws_security_group.server.id]

  associate_public_ip_address = false

  lifecycle {
    create_before_destroy = true
  }
  user_data = file("ec2userfile.sh")
}

resource "aws_security_group" "server" {
  name   = "${var.environemnt_code}-server"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [ aws_security_group.lb.id ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "server" {
  name                 = var.environemnt_code
  desired_capacity     = 2
  min_size             = 2
  max_size             = 5
  force_delete         = true
  launch_configuration = aws_launch_configuration.server.id
  vpc_zone_identifier  = aws_subnet.private.*.id
  target_group_arns    = [aws_lb_target_group.server.arn]
}
