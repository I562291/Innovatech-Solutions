terraform {
  backend "s3" {
    bucket  = "innovatech-terraform-statebucket"
    key = "terraform.tfstate"
    region  = "eu-central-1"                      
    encrypt = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_vpc" "hub_vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true


  tags = {
    Name = "HUB"
  }
}

resource "aws_subnet" "ALB_subnet1" {
  vpc_id     = aws_vpc.hub_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "ALB-Subnet"
  }
}

resource "aws_subnet" "ALB_subnet2" {
  vpc_id     = aws_vpc.hub_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "ALB-Subnet"
  }
}

resource "aws_subnet" "Proxy_subnet" {
  vpc_id     = aws_vpc.hub_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "Proxy-Subnet"
  }
}

resource "aws_vpc" "spoke_vpc" {
  cidr_block           = "10.1.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "Spoke"
  }
}

resource "aws_subnet" "web_subnet" {
  vpc_id     = aws_vpc.spoke_vpc.id
  cidr_block = "10.1.1.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "Webserver-Subnet"
  }
}

resource "aws_subnet" "db_subnet" {
  vpc_id     = aws_vpc.spoke_vpc.id
  cidr_block = "10.1.2.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "Database-Subnet"
  }
}

resource "aws_vpc_peering_connection" "hub_spoke_peering" {
  vpc_id      = aws_vpc.hub_vpc.id
  peer_vpc_id = aws_vpc.spoke_vpc.id
  auto_accept = true

  tags = {
    Name = "Hub-Spoke-Peering"
  }
}

resource "aws_route_table" "hub_route_table" {
  vpc_id = aws_vpc.hub_vpc.id

  route {
    cidr_block                = "10.1.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.hub_spoke_peering.id
  }

  tags = {
    Name = "Hub-Route-Table"
  }
}

resource "aws_route_table" "spoke_route_table" {
  vpc_id = aws_vpc.spoke_vpc.id

  route {
    cidr_block                = "10.0.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.hub_spoke_peering.id
  }

  tags = {
    Name = "Spoke-Route-Table"
  }
}

resource "aws_route_table_association" "alb1_route_table_association" {
  subnet_id      = aws_subnet.ALB_subnet1.id
  route_table_id = aws_route_table.hub_route_table.id
}

resource "aws_route_table_association" "alb2_route_table_association" {
  subnet_id      = aws_subnet.ALB_subnet2.id
  route_table_id = aws_route_table.hub_route_table.id
}

resource "aws_route_table_association" "proxy_route_table_association" {
  subnet_id      = aws_subnet.Proxy_subnet.id
  route_table_id = aws_route_table.hub_route_table.id
}

resource "aws_route_table_association" "web_route_table_association" {
  subnet_id      = aws_subnet.web_subnet.id
  route_table_id = aws_route_table.spoke_route_table.id
}

resource "aws_route_table_association" "db_route_table_association" {
  subnet_id      = aws_subnet.db_subnet.id
  route_table_id = aws_route_table.spoke_route_table.id
}