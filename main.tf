provider "aws" {
  region = "eu-west-1"
}

# VPC
resource "aws_vpc" "wordpress_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "WordPress-VPC"
  }
}

# Subnet
resource "aws_subnet" "wordpress_subnet" {
  vpc_id            = aws_vpc.wordpress_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "WordPress-subnet-01"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "wordpress_igw" {
  vpc_id = aws_vpc.wordpress_vpc.id
  tags = {
    Name = "WordPress-AWS-Internet-Gateway"
  }
}

# Route Table
resource "aws_route_table" "wordpress_route_table" {
  vpc_id = aws_vpc.wordpress_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wordpress_igw.id

  }
  tags = {
    Name = "WordPress-AWS-Route-Table"
  }
  
}

# Connect route table with subnet
resource "aws_route_table_association" "wordpress_route_table_association" {
  subnet_id      = aws_subnet.wordpress_subnet.id
  route_table_id = aws_route_table.wordpress_route_table.id
  
}

# Security Group
resource "aws_security_group" "wordpress_sg" {
  vpc_id = aws_vpc.wordpress_vpc.id

  name        = "wordpress_sg"
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "wordpress_sg"
  }
}

# Key Pair
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "wordpress_key" {
  key_name   = "wordpress_key"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "wordpress_key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "wordpresskey.pem"
}

# Fetch latest AMI
data "aws_ami" "wordpress" {
  most_recent = true
  owners      = ["679593333241"]
  filter {
    name   = "name"
    values = ["bitnami-wordpress-6.5.4-2-r02-linux-debian-12-x86_64-hvm-ebs-nami-7d426cb7-9522-4dd7-a56b-55dd8cc1c8d0"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

output "ami_id" {
  value = data.aws_ami.wordpress.id
}

# EC2 Instance
resource "aws_instance" "wordpress" {
  ami                         = data.aws_ami.wordpress.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.wordpress_key.key_name
  subnet_id                   = aws_subnet.wordpress_subnet.id
  vpc_security_group_ids      = [aws_security_group.wordpress_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "WordPress-EC2-Instance-01"
  }

  depends_on = [
    aws_vpc.wordpress_vpc,
    aws_subnet.wordpress_subnet,
    aws_security_group.wordpress_sg,
    aws_key_pair.wordpress_key
  ]
}








