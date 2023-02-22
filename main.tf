terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}


provider "aws" {
  region = "ap-south-1"
}

#!Resources

#! [1] Creating a VPC 'Prod-VPC'

resource "aws_vpc" "Prod-VPC" {
  cidr_block = var.CIDR-Production-subnet

  tags = {
    Name = "Production-VPC"
  }
}

#! [2] Create Internet Gateway 'Prod-IGW'

resource "aws_internet_gateway" "Prod-IGW" {
  vpc_id = aws_vpc.Prod-VPC.id

  tags = {
    Name = "Production-IGW"
  }
}

#! [3] Create Custom Route Table 'Prod-RT'

resource "aws_route_table" "Prod-RT" {
  vpc_id = aws_vpc.Prod-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Prod-IGW.id
  }
  tags = {
    Name = "Production-RouteTable"
  }
}

#! [4] Create a Subnet 'Prod-subnet-1'

resource "aws_subnet" "Prod-subnet-1" {
  vpc_id            = aws_vpc.Prod-VPC.id
  cidr_block        = var.CIDR-Production-subnet
  availability_zone = "ap-south-1a"
  tags = {
    "Name" = "Production subnet 1"
  }
}


#! [5] Associate the subnet to the Route Table 

resource "aws_route_table_association" "Route-Association" {
  subnet_id      = aws_subnet.Prod-subnet-1.id
  route_table_id = aws_route_table.Prod-RT.id

}

#! [6] Creating  security group 'Prod-SG'

resource "aws_security_group" "Prod-SG" {
  name        = "Prod-SG"
  description = "Allow Internet traffic "
  vpc_id      = aws_vpc.Prod-VPC.id

  dynamic "ingress" {
    iterator = port
    for_each = var.ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allowing web traffic "
  }

}

#! [7] creating an ENI to attach IP 'Prod-ENI' 

resource "aws_network_interface" "Prod-ENI" {
  subnet_id       = aws_subnet.Prod-subnet-1.id
  private_ips     = ["10.192.10.50"]
  security_groups = [aws_security_group.Prod-SG.id]

}

#! [8] Attaching an Elastic IP address to Prod-ENI

resource "aws_eip" "Prod-EIP" {
  vpc                       = true
  network_interface         = aws_network_interface.Prod-ENI.id
  associate_with_private_ip = "10.192.10.50"
  depends_on                = [aws_internet_gateway.Prod-IGW]
}


#! [9] Creating an ubuntu instance and installing apache2

resource "aws_instance" "Prod_server" {
  ami               = "ami-062df10d14676e201"
  instance_type     = "t2.micro"
  availability_zone = "ap-south-1a"
 # key_name          = "Prod-KeyPair"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.Prod-ENI.id
  }
  user_data = <<EOF
#!/bin/bash
sudo apt-get update
sudo apt-get install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
echo "The page was created by the user data" | sudo tee /var/www/html/index.html
EOF

  tags = {
    Name = "Production Server test1 "
  }
}




