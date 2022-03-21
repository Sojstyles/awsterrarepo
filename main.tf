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

data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm-*-x86_64-gp2"
    ]
  }
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_key_pair" "deployer" {
  key_name   = "awssecondkey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD8Dvx43SzhZWmffWwk7Nxt9MMx3IA0xNIAuak/SqZ5QJooOH8I/p3sSPthOfy8W5H0TzbxTYBfQQ4iOdFOenOCYGsGVQfq9Q9WbpW40gFCrueKAnzxq2HA2M1Qwh+ei7UAf86XsKbvYHPc3T6V8NU1M4Sj/guC9i0Zm3u+MO5hIaZbAQ/AdmpcznI6sU9ThuEBW2yOBadtAlS8VquJnVs7/jcK/Dw9cnuhljU3dg60sN2dRIOJQqEE/ik77FOn8StQFEJq/aF+1wHFSJ2EMGQO6olhCo5kTQiNSGxT4MCwf2QHqXhLchVRBP8jzt0yHgX0gccmmcm/N1OMahinR1Dv techstellar@TechStellar"
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
