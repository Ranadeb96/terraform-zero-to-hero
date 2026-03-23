# Define the AWS provider configuration.
provider "aws" {
  region = "ap-south-1"  # Replace with your desired AWS region.
}

variable "cidr" {
  default = "10.1.0.0/16"
}

resource "aws_key_pair" "localkey" {
  key_name   = "localkey"  # Replace with your desired key name
  public_key = file("~/.ssh/id_rsa.pub") # Replace with the path to your public key file
}

resource "aws_vpc" "mycustomvpc" {
  cidr_block = var.cidr
}

resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.mycustomvpc.id
  cidr_block              = "10.1.0.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.mycustomvpc.id
}

resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.mycustomvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_security_group" "webSg" {
  name   = "web"
  vpc_id = aws_vpc.mycustomvpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
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
    Name = "Web-sg"
  }
}

resource "aws_instance" "Ansible-VM" {
  ami                    = "ami-03695d52f0d883f65"
  instance_type          = "t3.micro"
  key_name      = aws_key_pair.localkey.key_name
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id              = aws_subnet.sub1.id

  connection {
    type        = "ssh"
    user        = "ec2-user"  # Replace with the appropriate username for your EC2 instance
    private_key = file("~/.ssh/id_rsa")  # Replace with the path to your private key
    host        = self.public_ip
  }
}

resource "aws_instance" "Ansible-VM-1" {
  ami                    = "ami-03695d52f0d883f65"
  instance_type          = "t3.micro"
  key_name      = aws_key_pair.localkey.key_name
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id              = aws_subnet.sub1.id

  connection {
    type        = "ssh"
    user        = "ec2-user"  # Replace with the appropriate username for your EC2 instance
    private_key = file("~/.ssh/id_rsa")  # Replace with the path to your private key
    host        = self.public_ip
  }
}
