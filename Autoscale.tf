resource "aws_launch_configuration" "my_launch_configuration" {

  # Amazon Linux 2 AMI (HVM), SSD Volume Type.
  image_id = data.aws_ami.amazonlinux.id

  instance_type   = "t2.micro"
  key_name        = "thirdkey"
  security_groups = [aws_security_group.my_launch_config_security_group.id]

  # set to false on prod stage.
  # otherwise true, because ssh access might be needed to the instance.
  associate_public_ip_address = false

  lifecycle {
    # ensure the new instance is only created before the other one is destroyed.
    create_before_destroy = true
  }

  # execute bash scripts inside deployment.sh on instance's bootstrap.
  # what the bash scripts going to do in summary:
  # fetch a hello world app from Github repo, then deploy it in the instance.
  user_data = file("ec2userfile.sh")
}

# security group for launch config my_launch_configuration.
resource "aws_security_group" "my_launch_config_security_group" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# create an autoscaling then attach it into my_alb_target_group.
resource "aws_autoscaling_attachment" "my_aws_autoscaling_attachment" {
  alb_target_group_arn   = aws_lb_target_group.my_alb_target_group.arn
  autoscaling_group_name = aws_autoscaling_group.my_autoscaling_group.id
}

# define the autoscaling group.
# attach my_launch_configuration into this newly created autoscaling group below.
resource "aws_autoscaling_group" "my_autoscaling_group" {
  name             = "my-autoscaling-group"
  desired_capacity = 2 # ideal number of instance alive
  min_size         = 2 # min number of instance alive
  max_size         = 5 # max number of instance alive

  # allows deleting the autoscaling group without waiting
  # for all instances in the pool to terminate
  force_delete = true

  launch_configuration = aws_launch_configuration.my_launch_configuration.id
  vpc_zone_identifier = [
    aws_subnet.public[0].id, aws_subnet.public[1].id,
  ]

  timeouts {
    delete = "15m" # timeout duration for instances
  }

  lifecycle {
    # ensure the new instance is only created before the other one is destroyed.
    create_before_destroy = true
  }
}
# print load balancer's DNS, test it using curl.
#
# curl my-alb-625362998.ap-southeast-1.elb.amazonaws.com
output "alb-url" {
  value = aws_lb.my_alb.dns_name
}
