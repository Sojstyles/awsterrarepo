terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-awsdevops-state"
    key            = "dc-us/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "tf-state-run-locks"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
}

data "aws_ami" "amazonlinux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"]
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

locals {
  public_cidr  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_cidr = ["10.0.2.0/24", "10.0.3.0/24"]
}

resource "aws_subnet" "public" {
  count = length(local.public_cidr)

  vpc_id     = aws_vpc.main.id
  cidr_block = local.public_cidr[count.index]

  tags = {
    Name = "${var.environemnt_code}-public${count.index}"
  }
}

resource "aws_subnet" "private" {
  count = length(local.private_cidr)

  vpc_id     = aws_vpc.main.id
  cidr_block = local.private_cidr[count.index]

  tags = {
    Name = "${var.environemnt_code}-private${count.index}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.environemnt_code
  }
}

resource "aws_eip" "nat" {
  count = length(local.public_cidr)

  vpc = true
}

resource "aws_nat_gateway" "main" {
  count = length(local.public_cidr)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = var.environemnt_code
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.environemnt_code}-public"
  }
}

resource "aws_route_table_association" "public" {
  count = length(local.public_cidr)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count = length(local.private_cidr)

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.environemnt_code}-private${count.index}"
  }
}

resource "aws_route_table_association" "private" {
  count = length(local.private_cidr)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# create an Application Load Balancer.
# attach the previous availability zones' subnets into this load balancer.

resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false         # set lb for public access
  load_balancer_type = "application" # use Application Load Balancer
  security_groups    = [aws_security_group.TerraformEC2_security.id]
  subnets = [ # attach the availability zones' subnets.
    aws_subnet.primary.id, aws_subnet.secondary.id,
  ]
}

resource "aws_security_group" "my_alb_security_group" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
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

# create an alb listener for my_alb.
# forward rule: only accept incoming HTTP request on port 80,
# then it'll be forwarded to port target:8080.
resource "aws_lb_listener" "my_alb_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.my_alb_target_group.arn
    type             = "forward"
  }
}

# my_alb will forward the request to a particular app,
# that listen on 8080 within instances on my_vpc.
resource "aws_lb_target_group" "my_alb_target_group" {
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

output "jump-box-details" {
  value = "${aws_instance.jump_box.private_ip} - ${aws_instance.jump_box.id} - ${aws_instance.jump_box.availability_zone}"
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = aws_vpc.main.id
  cidr_block = aws_vpc.main.cidr_block
}

# Declare the data source
data "aws_availability_zones" "available" {
  state = "available"
}

# e.g., Create subnets in the first two available availability zones

resource "aws_subnet" "primary" {
  count             = length(local.public_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = aws_vpc.main.cidr_block
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "${var.environemnt_code}-azzoneprimary"
  }

}

resource "aws_subnet" "secondary" {
  count             = length(local.public_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = aws_vpc.main.cidr_block
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.environemnt_code}-azzonesecondary"
  }

}

