# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "MY_VPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "HDFC_BANK"
  }
}

resource "aws_subnet" "PUBLIC_SUBNET" {
  vpc_id     = aws_vpc.MY_VPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "HDFC_PUBLIC_SUBNET"
  }
}

resource "aws_subnet" "PRIVATE_SUBNET" {
  vpc_id     = aws_vpc.MY_VPC.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "HDFC_PRIVATE_SUBNET"
  }
}

resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.MY_VPC.id

  tags = {
    Name = "HDFC_IGW"
  }
}

resource "aws_route_table" "PUBLIC_ROUTE_TABLE" {
  vpc_id = aws_vpc.MY_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }

  tags = {
    Name = "HDFC_PUBLIC_ROUTE_TABLE"
  }
}

resource "aws_route_table_association" "PUBLIC_RT_ASS" {
  subnet_id      = aws_subnet.PUBLIC_SUBNET.id
  route_table_id = aws_route_table.PUBLIC_ROUTE_TABLE.id
}

resource "aws_eip" "eip" {
  domain      = "vpc"
}

resource "aws_nat_gateway" "NAT_GW" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.PUBLIC_SUBNET.id

  tags = {
    Name = "HDFC_NAT_GW"
  }
}

resource "aws_route_table" "PRIVATE_ROUTE_TABLE" {
  vpc_id = aws_vpc.MY_VPC.id
  route {
    cidr_block     = "0.0.0.0/0"
    gateway_id     = aws_nat_gateway.NAT_GW.id
  }

  tags = {
    Name = "HDFC_PRIVATE_ROUTE_TABLE"
  }
}

resource "aws_route_table_association" "PRIVATE_RT_ASS" {
  subnet_id      = aws_subnet.PRIVATE_SUBNET.id
  route_table_id = aws_route_table.PRIVATE_ROUTE_TABLE.id
}

resource "aws_security_group" "PUBSG" {
  name        = "PUBSG"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.MY_VPC.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "HDFC_PUB_SG"
  }
}

resource "aws_security_group" "PRI_SG" {
  name        = "PRI_SG"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.MY_VPC.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["10.0.1.0/24"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "hdfc_pri_sg"
  }
}


resource "aws_instance" "PUB_VM" {
  ami                                             = "ami-0f559c3642608c138"
  instance_type                                   = "t2.micro"
  availability_zone                               = "ap-south-1"
  associate_public_ip_address                     = "true"
  vpc_security_group_ids                          = [aws_security_group.PUBSG.id]
  subnet_id                                       = aws_subnet.PUBLIC_SUBNET.id
  key_name                                        = "jack"

    tags = {
    Name = "HDFCBANK WEBSERVER"
  }
}

resource "aws_instance" "PRI_VM" {
  ami                                             = "ami-0f559c3642608c138"
  instance_type                                   = "t2.micro"
  availability_zone                               = "ap-south-1"
  associate_public_ip_address                     = "false"
  vpc_security_group_ids                          = [aws_security_group.PRI_SG.id]
  subnet_id                                       = aws_subnet.PRIVATE_SUBNET.id
  key_name                                        = "jack"

    tags = {
    Name = "HDFCBANK WEBSERVER"
  }
}