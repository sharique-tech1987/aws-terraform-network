# Create a VPC
resource "aws_vpc" "vprofile_VPC" {
  cidr_block = "172.20.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name    = "vprofile-VPC"    
  }
}

# Create 2 public subnets
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

# Create internet gateway and attached to
# vprofile-VPC
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

# Create route to provide public access to 
# vprofile-VPC
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vprofile_IGW.id
  }

  tags = {
    Name = "vpro-pub-RT"
  }
}

# Associate subnets to route table
resource "aws_route_table_association" "vpro_pub_sub_assoc_1" {
  subnet_id      = aws_subnet.vpro_pubsub_1.id
  route_table_id = aws_route_table.vpro_pub_RT.id
}

resource "aws_route_table_association" "vpro_pub_sub_assoc_2" {
  subnet_id      = aws_subnet.vpro_pubsub_2.id
  route_table_id = aws_route_table.vpro_pub_RT.id
}

resource "aws_security_group" "web01_sg" {
  name        = "web01-sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.vprofile_VPC.id

  tags = {
    Name = "web01-sg"
  }


# Add default rule to allow all outboud traffic
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Add inbound rule to allow Http traffic 
resource "aws_vpc_security_group_ingress_rule" "allow_port_80_ipv4" {
  security_group_id = aws_security_group.web01_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# Add inbound rule to allow SSH traffic
resource "aws_vpc_security_group_ingress_rule" "allow_port_22" {
  security_group_id = aws_security_group.web01_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# Allow traffic from ELB security group
resource "aws_vpc_security_group_ingress_rule" "allow_port_80_for_ELB" {
  security_group_id = aws_security_group.web01_sg.id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  referenced_security_group_id = aws_security_group.web_elb_sg.id
}

# Upload public key to AWS
resource "aws_key_pair" "web01_key" {
  key_name   = "web01key"
  public_key = file("./keys/web01key.pub")
}

# Upload public key to AWS
resource "aws_key_pair" "web02_key" {
  key_name   = "web02key"
  public_key = file("./keys/web02key.pub")
}

# Add security group Elastic Load Balancer
resource "aws_security_group" "web_elb_sg" {
  name        = "web-ELB-SG"
  description = "Allow HTTP traffic for ELB"
  vpc_id      = aws_vpc.vprofile_VPC.id

  tags = {
    Name = "web-ELB-SG"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Add IPv4 rule for Elastic Load Balancer
resource "aws_vpc_security_group_ingress_rule" "allow_port_80_elb_ipv4" {
  security_group_id = aws_security_group.web_elb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# Add IPv6 rule for Elastic Load Balancer
resource "aws_vpc_security_group_ingress_rule" "allow_port_80_elb_ipv6" {
  security_group_id = aws_security_group.web_elb_sg.id
  cidr_ipv6         = "::/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# Create EC2 Instance for public subnet 1
resource "aws_instance" "web01_inst" {
  ami                    = var.AMIS[var.REGION]
  instance_type          = "t2.micro"
  availability_zone      = var.ZONE1
  subnet_id     = aws_subnet.vpro_pubsub_1.id
  key_name               = aws_key_pair.web01_key.key_name
  vpc_security_group_ids = [aws_security_group.web01_sg.id]
  tags = {
    Name    = "Web01"
  }

  provisioner "file" {
    source      = "web.sh"
    destination = "/tmp/web.sh"
  }

  provisioner "remote-exec" {

    inline = [
      "chmod +x /tmp/web.sh",
      "sudo /tmp/web.sh"
    ]
  }

  connection {
    user        = var.USER
    private_key = file("./keys/web01key")
    host        = self.public_ip
  }
}

# Create EC2 Instance for public subnet 2
resource "aws_instance" "web02_inst" {
  ami                    = var.AMIS[var.REGION]
  instance_type          = "t2.micro"
  availability_zone      = var.ZONE2
  subnet_id     = aws_subnet.vpro_pubsub_2.id
  key_name               = aws_key_pair.web02_key.key_name
  vpc_security_group_ids = [aws_security_group.web01_sg.id]
  tags = {
    Name    = "Web02"
  }

  provisioner "file" {
    source      = "web.sh"
    destination = "/tmp/web.sh"
  }

  provisioner "remote-exec" {

    inline = [
      "chmod +x /tmp/web.sh",
      "sudo /tmp/web.sh"
    ]
  }

  connection {
    user        = var.USER
    private_key = file("./keys/web02key")
    host        = self.public_ip
  }
}

# Create target group for ELB
resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vprofile_VPC.id
}

# Register web01 with target group
resource "aws_lb_target_group_attachment" "web_tg_attach" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web01_inst.id
  port             = 80
}

# Register web02 with target group
resource "aws_lb_target_group_attachment" "web_tg_attach_web02" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web02_inst.id
  port             = 80
}

# Create Elastic Load Balancer
resource "aws_lb" "vpro_web_elb" {
  name               = "vpro-web-elb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_elb_sg.id]
  subnets            = [aws_subnet.vpro_pubsub_1.id, aws_subnet.vpro_pubsub_2.id]

  enable_deletion_protection = false

  tags = {
    Environment = "staging"
  }
}

# Add listner for ELB
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.vpro_web_elb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}