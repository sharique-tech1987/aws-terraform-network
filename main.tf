resource "aws_vpc" "vprofile_VPC" {
  cidr_block = "172.20.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name    = "vprofile-VPC"    
  }
}

resource "aws_subnet" "vpro_pubsub_1" {
  vpc_id     = aws_vpc.vprofile_VPC.id
  availability_zone = var.ZONE1
  cidr_block = "172.20.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "vpro-pubsub-1"
  }
}

resource "aws_subnet" "vpro_pubsub_2" {
  vpc_id     = aws_vpc.vprofile_VPC.id
  availability_zone = var.ZONE2
  cidr_block = "172.20.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "vpro-pubsub-2"
  }
}

resource "aws_internet_gateway" "vprofile_IGW" {
  vpc_id = aws_vpc.vprofile_VPC.id

  tags = {
    Name = "vprofile-IGW"
  }
}

resource "aws_route_table" "vpro_pub_RT" {
  vpc_id = aws_vpc.vprofile_VPC.id

  route {
    cidr_block = "172.20.0.0/16"
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vprofile_IGW.id
  }

  tags = {
    Name = "vpro-pub-RT"
  }
}

resource "aws_route_table_association" "vpro_pub_sub_assoc_1" {
  subnet_id      = aws_subnet.vpro_pubsub_1.id
  route_table_id = aws_route_table.vpro_pub_RT.id
}

resource "aws_route_table_association" "vpro_pub_sub_assoc_2" {
  subnet_id      = aws_subnet.vpro_pubsub_2.id
  route_table_id = aws_route_table.vpro_pub_RT.id
}