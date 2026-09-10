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

resource "aws_internet_gateway" "hub_internet_gateway" {
  vpc_id = aws_vpc.hub_vpc.id

  tags = {
    Name = "Hub-Internet-Gateway"
  }
}

resource "aws_alb" "hub_alb" {
  name               = "hub-alb"
  internal           = false
  subnets            = [aws_subnet.ALB_subnet1.id, aws_subnet.ALB_subnet2.id]

  enable_deletion_protection = true

  tags = {
    Name = "Hub-ALB"
  }
}

#------------------------------------------------------------------------------------------------------------------------
# This is meant for the ec2 instances to know what version of the OS they need to use for the Virtual Machine (template)
data "aws_ssm_parameter" "al2023_arm64" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.18-arm64"
}

# This amazon machine image is optimized for ECS
data "aws_ssm_parameter" "ecs_al2023_arm64" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/arm64/recommended/image_id"
}
#------------------------------------------------------------------------------------------------------------------------

resource "aws_instance" "proxy_hub" {
  ami           = data.aws_ssm_parameter.al2023_arm64.value
  instance_type = "t4g.nano"
  subnet_id     = aws_subnet.Proxy_subnet.id

  tags = {
    Name = "Proxy-Hub"
  }
}

resource "aws_instance" "monitoring_hub" {
  ami           = data.aws_ssm_parameter.al2023_arm64.value
  instance_type = "t4g.small"
  subnet_id     = aws_subnet.Monitoring_subnet.id

  tags = {
    Name = "Monitoring-Hub"
  }
}

resource "aws_vpn_gateway" "hub_vpn_gateway" {
  vpc_id = aws_vpc.hub_vpc.id

  tags = {
    Name = "Hub-VPN-Gateway"
  }
}

# Hub subnets
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

resource "aws_subnet" "Monitoring_subnet" {
  vpc_id     = aws_vpc.hub_vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "Monitoring-Subnet"
  }
}

# Spoke VPC and subnets
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

resource "aws_subnet" "db_subnet2" {
  vpc_id     = aws_vpc.spoke_vpc.id
  cidr_block = "10.1.3.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "Database-Subnet"
  }
}

# Subnet group for the database (je moet een database subnet groep maken zodat aws weet welke subnets gebruikt mogen worden als een database uitvalt)
resource "aws_db_subnet_group" "database_subnet_group"{
  name = "database_subnet_group"
  subnet_ids = [
    aws_subnet.db_subnet.id,
    aws_subnet.db_subnet2.id
  ]
}

# This is the ecs
resource "aws_ecs_cluster" "ecs" {
  name = "web-cluster"
}

# This is the webserver
resource "aws_instance" "webserver_ec2" {
  ami           = data.aws_ssm_parameter.ecs_al2023_arm64.value
  instance_type = "t4g.small"
  subnet_id     = aws_subnet.web_subnet.id
  iam_instance_profile = aws_iam_instance_profile.ecs_instance_profile.name

  user_data = <<-EOF
    #!/bin/bash
    echo "ECS_CLUSTER=${aws_ecs_cluster.ecs.name}" >> /etc/ecs/ecs.config
  EOF

  tags = {
    Name = "Webserver"
    Role = "Web-ECS-Host"
  }
}

# IAM role for the ec2 so the ecs agent can communicate with the ecs cluster via the ec2. (hier wordt de rol gemaakt)
resource "aws_iam_role" "ecs_instance_role" {
  name = "ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Assign the IAM role the standard ECS permissions required by an EC2 host. (hier zorgen we ervoor dat de rol de juiste rechten heeft die een ec2 nodig heeft om met de ecs te kunnen praten)
resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# We assign the role to the instance profile
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

# This is the RDS instance / Database (we voegen hier de subnet groep aan toe van de database)
resource "aws_db_instance" "database" {
  identifier = "innovatech-database"

  engine         = "mysql"
  instance_class = "db.t4g.micro" #goedkoop

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  username = "admin"
  password = "student"

  db_subnet_group_name = aws_db_subnet_group.database_subnet_group.name
  publicly_accessible = false
  skip_final_snapshot = true
}

# VPC Peering Connection between Hub and Spoke VPCs
resource "aws_vpc_peering_connection" "hub_spoke_peering" {
  vpc_id      = aws_vpc.hub_vpc.id
  peer_vpc_id = aws_vpc.spoke_vpc.id
  auto_accept = true

  tags = {
    Name = "Hub-Spoke-Peering"
  }
}

# Route Tables for Hub and Spoke VPCs
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

resource "aws_route_table" "igw_route_table" {
  vpc_id = aws_vpc.hub_vpc.id

  route {
    cidr_block                = "0.0.0.0/0"
    gateway_id                = aws_internet_gateway.hub_internet_gateway.id
  }

  route {
    cidr_block                = "10.1.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.hub_spoke_peering.id
  }

  tags = {
    Name = "igw-Route-Table"
  }
}

# Route table associations, for public subnets associated with the internet gateway route table
resource "aws_route_table_association" "alb1_route_table_association" {
  subnet_id      = aws_subnet.ALB_subnet1.id
  route_table_id = aws_route_table.igw_route_table.id
}

resource "aws_route_table_association" "alb2_route_table_association" {
  subnet_id      = aws_subnet.ALB_subnet2.id
  route_table_id = aws_route_table.igw_route_table.id
}

# Route table associations, for private subnets associated with the hub and spoke route tables
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

resource "aws_route_table_association" "db2_route_table_association" {
  subnet_id      = aws_subnet.db_subnet2.id
  route_table_id = aws_route_table.spoke_route_table.id
}

resource "aws_route_table_association" "monitoring_route_table_association" {
  subnet_id      = aws_subnet.Monitoring_subnet.id
  route_table_id = aws_route_table.hub_route_table.id
}
