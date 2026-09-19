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
  tags = {
    Project = "innovatech_solutions"
    Name    = "monitoring_SG"
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

resource "aws_lb_target_group" "alb_webserver_tg" { # de ecs zal hier later aan toegevoegd worden om de webserver destinatie mee te geven
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
# 1. Haal automatisch de nieuwste ECS-Optimized AMI op voor T2 (Amazon Linux 2)
data "aws_ssm_parameter" "ec2_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id" # ECS optimized AMI voor amazon linux 2
}

# 2. De blauwdruk voor je EC2 webservers
resource "aws_launch_template" "ecs_webserver_template" {
  name_prefix   = "ecs-webserver-"
  image_id      = data.aws_ssm_parameter.ec2_ami.value
  instance_type = "t2.micro" # t2.micro free tier. you can always expand ec2 during expansion.

  network_interfaces {
    associate_public_ip_address = false 
    security_groups             = [aws_security_group.webserver_SG.id] 
  }

  # Dit linkt de EC2-computer aan je ECS-cluster.
  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=innovatech-cluster >> /etc/ecs/ecs.config
              EOF
  )
}


resource "aws_autoscaling_group" "webserver_asg" {
  name                = "webserver-asg"
  vpc_zone_identifier = [aws_subnet.Webserver_subnet1.id, aws_subnet.Webserver_subnet2.id]
  desired_capacity    = 2
  max_size            = 3
  min_size            = 2

  # Dit zorgt ervoor dat de Autoscaler ingrijpt als de ALB health check faalt
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.ecs_webserver_template.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
  tags = {
    Project = "innovatech_solutions"
    Name    = "webserver_asg"
  }
}

# Het ECS Cluster (De manager van je containers) waar je ec2 instances in zitten.
resource "aws_ecs_cluster" "innovatech_ecs_cluster" {
  name = "innovatech-cluster"
  
  tags = {
    Project = "innovatech_solutions"
    Name    = "innovatech_ecs_cluster"
  }
}

# Een container registry waar ik mijn image in opsla.
resource "aws_ecr_repository" "container_registry" {
  name                 = "container_registry"
}

# De Task Definition, instructies voor de ecs cluster voor een container (welke image?)
resource "aws_ecs_task_definition" "webserver_task" {
  family                   = "webserver-task"
  network_mode             = "awsvpc" # awsvpc is nodig voor de alb target group omdat het de ip's van de containers doorstuurt naar de alb
  requires_compatibilities = ["EC2"] # ec2 over fargate. fargate = serverless, maar duurder en minder control
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "webserver"
      # hier koppelen we de URL dynamisch aan de image die we in de ECR hebben gepusht
      image     = "${aws_ecr_repository.container_registry.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

# De ECS Service (Zorgt dat er altijd 2 containers draaien en koppelt aan de ALB)
resource "aws_ecs_service" "webserver_service" {
  name            = "webserver-service"
  cluster         = aws_ecs_cluster.innovatech_ecs_cluster.id
  task_definition = aws_ecs_task_definition.webserver_task.arn
  desired_count   = 2
  launch_type     = "EC2"

  network_configuration {
    subnets         = [aws_subnet.Webserver_subnet1.id, aws_subnet.Webserver_subnet2.id]
    security_groups = [aws_security_group.webserver_SG.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_webserver_tg.arn # koppelt de alb target group aan de ecs service zodat de alb weet waar hij de requests heen moet sturen
    container_name   = "webserver"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.alb_listener]
}

resource "aws_autoscaling_policy" "scaling_policy" {
  name                   = "scaling_policy" 
  autoscaling_group_name = aws_autoscaling_group.webserver_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}