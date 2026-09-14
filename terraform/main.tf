provider "aws" {
  region = "eu-central-1"
}

# Networking
resource "aws_vpc" "vpc_innovatech_solutions" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Project = "innovatech_solutions"
    Name    = "vpc_innovatech_solutions"
  }
}

resource "aws_subnet" "ALB_subnet1" {
  vpc_id            = aws_vpc.vpc_innovatech_solutions.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Project = "innovatech_solutions"
    Name    = "ALB_subnet1"
  }
}

resource "aws_subnet" "ALB_subnet2" {
  vpc_id            = aws_vpc.vpc_innovatech_solutions.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Project = "innovatech_solutions"
    Name    = "ALB_subnet2"
  }
}

resource "aws_subnet" "Monitoring_subnet" {
  vpc_id            = aws_vpc.vpc_innovatech_solutions.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Project = "innovatech_solutions"
    Name    = "Monitoring_subnet"
  }
}

resource "aws_subnet" "VPN_subnet" {
  vpc_id            = aws_vpc.vpc_innovatech_solutions.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Project = "innovatech_solutions"
    Name    = "VPN_subnet"
  }
}

resource "aws_subnet" "Webserver_subnet1" {
  vpc_id            = aws_vpc.vpc_innovatech_solutions.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Project = "innovatech_solutions"
    Name    = "Webserver_subnet1"
  }
}

resource "aws_subnet" "Webserver_subnet2" {
  vpc_id            = aws_vpc.vpc_innovatech_solutions.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Project = "innovatech_solutions"
    Name    = "Webserver_subnet2"
  }
}

resource "aws_subnet" "Database_subnet1" {
  vpc_id            = aws_vpc.vpc_innovatech_solutions.id
  cidr_block        = "10.0.7.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Project = "innovatech_solutions"
    Name    = "Database_subnet1"
  }
}

resource "aws_subnet" "Database_subnet2" {
  vpc_id            = aws_vpc.vpc_innovatech_solutions.id
  cidr_block        = "10.0.8.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Project = "innovatech_solutions"
    Name    = "Database_subnet2"
  }
}

# Routing
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.vpc_innovatech_solutions.id

  tags = {
    Project = "innovatech_solutions"
    Name    = "IGW"
  }
}

resource "aws_eip" "NAT_EIP" {
  domain = "vpc" # Public Elastic IP used by the NAT Gateway

  tags = {
    Project = "innovatech_solutions"
    Name    = "NAT_EIP"
  }
}

resource "aws_nat_gateway" "NAT" {
  allocation_id = aws_eip.NAT_EIP.id
  subnet_id     = aws_subnet.ALB_subnet1.id

  tags = {
    Project = "innovatech_solutions"
    Name    = "NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.IGW]
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.vpc_innovatech_solutions.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }

  tags = {
    Project = "innovatech_solutions"
    Name    = "public_route"
  }
}

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.vpc_innovatech_solutions.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT.id
  }

  tags = {
    Project = "innovatech_solutions"
    Name    = "private_route"
  }
}

resource "aws_route_table" "isolated_route" {
  vpc_id = aws_vpc.vpc_innovatech_solutions.id

  tags = {
    Project = "innovatech_solutions"
    Name    = "isolated_route"
  }
}

resource "aws_route_table_association" "ALB_subnet1_association" {
  subnet_id      = aws_subnet.ALB_subnet1.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "ALB_subnet2_association" {
  subnet_id      = aws_subnet.ALB_subnet2.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "Monitoring_subnet_association" {
  subnet_id      = aws_subnet.Monitoring_subnet.id
  route_table_id = aws_route_table.private_route.id
}

resource "aws_route_table_association" "VPN_subnet_association" {
  subnet_id      = aws_subnet.VPN_subnet.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "Webserver_subnet1_association" {
  subnet_id      = aws_subnet.Webserver_subnet1.id
  route_table_id = aws_route_table.private_route.id
}

resource "aws_route_table_association" "Webserver_subnet2_association" {
  subnet_id      = aws_subnet.Webserver_subnet2.id
  route_table_id = aws_route_table.private_route.id
}

resource "aws_route_table_association" "Database_subnet1_association" {
  subnet_id      = aws_subnet.Database_subnet1.id
  route_table_id = aws_route_table.isolated_route.id
}

resource "aws_route_table_association" "Database_subnet2_association" {
  subnet_id      = aws_subnet.Database_subnet2.id
  route_table_id = aws_route_table.isolated_route.id
}

# Security Groups
resource "aws_security_group" "ALB_SG" {
  vpc_id = aws_vpc.vpc_innovatech_solutions.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.5.0/24", "10.0.6.0/24"]
  }

  tags = {
    Project = "innovatech_solutions"
    Name    = "ALB_SG"
  }
}

resource "aws_security_group" "webserver_SG" {
  vpc_id = aws_vpc.vpc_innovatech_solutions.id

  ingress { # ALB -> Webserver
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
  }

  ingress { # ALB -> Webserver
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
  }

  egress { # Webserver -> Database
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["10.0.7.0/24", "10.0.8.0/24"]
  }

  egress { # Webserver -> Internet (maybe this is not safe?)
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "innovatech_solutions"
    Name    = "webserver_SG"
  }
}

resource "aws_security_group" "database_SG" {
  vpc_id = aws_vpc.vpc_innovatech_solutions.id

  ingress { # Webserver -> Database
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.5.0/24", "10.0.6.0/24"]
  }

  ingress { # VPN -> Database
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.4.0/24"]
  }

  egress { # Database -> Webserver
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.5.0/24", "10.0.6.0/24"]
  }

  tags = {
    Project = "innovatech_solutions"
    Name    = "database_SG"
  }
}

resource "aws_security_group" "vpn_SG" {
  vpc_id = aws_vpc.vpc_innovatech_solutions.id

  ingress { # OpenVPN
    from_port   = 500
    to_port     = 500
    protocol    = "udp"
    cidr_blocks = ["145.220.75.5/32"]
  }

  egress { # VPN -> Database
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.7.0/24", "10.0.8.0/24"]
  }

  egress { # VPN -> Grafana
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["10.0.3.0/24"]
  }

  egress { # VPN -> Prometheus
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["10.0.3.0/24"]
  }

  tags = {
    Project = "innovatech_solutions"
    Name    = "vpn_SG"
  }
}

resource "aws_security_group" "monitoring_SG" {
  vpc_id = aws_vpc.vpc_innovatech_solutions.id

  ingress { # VPN -> Grafana
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["10.0.4.0/24"]
  }

  ingress { # VPN -> Prometheus
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["10.0.4.0/24"]
  }

  egress { # monitoring -> Internet (VIA NAT GATEWAY)
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Services