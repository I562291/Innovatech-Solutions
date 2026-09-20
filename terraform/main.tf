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

resource "aws_security_group" "database_sg" {
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
    Name    = "database_sg"
  }
}

resource "aws_security_group" "vpn_sg" {
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
    Name    = "vpn_sg"
  }
}

resource "aws_security_group" "monitoring_sg" {
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
  tags = {
    Project = "innovatech_solutions"
    Name    = "monitoring_sg"
  }
}

# Services
# ALB ------------------------------------------------------------------------------------------------
resource "aws_lb" "ALB" {
  name               = "ALB"
  internal           = false
  load_balancer_type = "application"

  security_groups    = [aws_security_group.ALB_SG.id]
  subnets = [
    aws_subnet.ALB_subnet1.id,
    aws_subnet.ALB_subnet2.id
  ]

  tags = {
    Project = "innovatech_solutions"
    Name    = "ALB"
  }
}

resource "aws_lb_target_group" "alb_webserver_tg" {
  name        = "webserver-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc_innovatech_solutions.id

  
  tags = {
    Project = "innovatech_solutions"
    Name    = "webserver_tg"
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.ALB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_webserver_tg.arn
  }

  tags = {
    Project = "innovatech_solutions"
    name = "alb_listener"
  }

}

# --------------------------------------------------------------------------------------------------------

# webserver ----------------------------------------------------------------------------------------------
# 1. 
data "aws_ssm_parameter" "ec2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# 2. De blauwdruk voor je EC2 webservers
resource "aws_launch_template" "template_ec2" {
  name_prefix   = "template_ec2-"
  image_id      = data.aws_ssm_parameter.ec2_ami.value
  instance_type = "t2.micro" # t2.micro free tier. We can always expand ec2 during expansion.

  network_interfaces {
    associate_public_ip_address = false 
    security_groups             = [aws_security_group.webserver_SG.id]
  }
  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_instance_profile.arn
  }

  # Deze script installeert Docker na deployment
  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y docker
              systemctl enable docker
              systemctl start docker
              aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin ${split("/", aws_ecr_repository.container_registry.repository_url)[0]}
              docker pull ${aws_ecr_repository.container_registry.repository_url}:latest
              docker run -d -p 80:80 --name mijn-web-app --restart always ${aws_ecr_repository.container_registry.repository_url}:latest
              EOF
  )
}


resource "aws_autoscaling_group" "webserver_asg" {
  name                = "webserver-asg"
  vpc_zone_identifier = [aws_subnet.Webserver_subnet1.id, aws_subnet.Webserver_subnet2.id]
  desired_capacity    = 2
  max_size            = 3
  min_size            = 2

  target_group_arns   = [aws_lb_target_group.alb_webserver_tg.arn]

  # Dit zorgt ervoor dat de Autoscaler ingrijpt als de ALB health check faalt
  health_check_type         = "ELB"
  health_check_grace_period = 300 # every 5 minutes

  launch_template { # hier vertellen we de autoscaler welke launch template hij moet gebruiken
    id      = aws_launch_template.template_ec2.id
    version = "$Latest"
  }
}

# Een container registry waar ik mijn image in opsla.
resource "aws_ecr_repository" "container_registry" {
  name                 = "container_registry"
}

resource "aws_autoscaling_policy" "scaling_policy" {
  name                   = "scaling_policy" 
  autoscaling_group_name = aws_autoscaling_group.webserver_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 80.0
  }
}

// Source - https://stackoverflow.com/a/57780806
// Posted by Dipendra Dangal
// Retrieved 20-09-2026

resource "aws_iam_role" "iam_role" {
  name = "test-role"

  assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
EOF
}

resource "aws_iam_policy" "iam_policy" {
  name        = "test-policy"
  description = "this is a iam_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment" {
  role       = "${aws_iam_role.iam_role.name}"
  policy_arn = "${aws_iam_policy.iam_policy.arn}"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "my-ec2-instance-profile"
  role = aws_iam_role.iam_role.name
}

# Monitoring ----------------------------------------------------------------------------------------------
resource "aws_instance" "monitoring_server" {
    ami           = data.aws_ssm_parameter.ec2_ami.value
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.Monitoring_subnet.id
    security_groups = [aws_security_group.monitoring_sg.id]
    user_data = <<-EOF
                #!/bin/bash
                dnf update -y
                dnf install -y prometheus
                dnf install -y grafana
                systemctl enable prometheus
                systemctl start prometheus
                systemctl enable grafana
                systemctl start grafana
                EOF
    

    tags = {
        Name    = "Monitoring Server"
        Project = "innovatech_solutions"
    }
}

# vpn server ----------------------------------------------------------------------------------------------
resource "aws_instance" "vpn_server" {
    ami           = data.aws_ssm_parameter.ec2_ami.value
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.VPN_subnet.id
    
    network_interfaces {
    associate_public_ip_address = true 
    security_groups             = [aws_security_group.vpn_sg.id]
  }
    user_data = <<-EOF
                #!/bin/bash
                dnf update -y
                dnf install -y openvpn
                systemctl enable openvpn
                systemctl start openvpn
                EOF
    tags = {
        Name    = "VPN Server"
        Project = "innovatech_solutions"
    }
}

# mysql database ----------------------------------------------------------------------------------------------
resource "aws_db_instance" "mysql" {
  identifier         = "mysql-instance"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t2.micro"
  allocated_storage  = 20
  username          = "admin"
  password          = "password"
  db_name          = "innovatech"
  skip_final_snapshot = true
  db_subnet_group_name = [
    aws_db_subnet_group.mysql_subnet_group.Database_subnet1, aws_db_subnet_group.mysql_subnet_group.Database_subnet2
  ]
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  tags = {
    Name    = "mysql"
    Project = "innovatech_solutions"
  }
}