provider "aws" {
  region = "eu-central-1"
}

data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "db_password" { # zodat terraform de database zijn wachtwoord kan geven tijdens deployment
  name            = "/innovatech/db/password"
  with_decryption = true
}

terraform {
  backend "s3" {
    bucket  = "innovatech-terraform-statebucket"
    key     = "innovatech/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}

# Networking
resource "aws_vpc" "vpc_innovatech_solutions" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Project = "innovatech_solutions"
    Name    = "vpc_innovatech_solutions"
  }
}

resource "aws_security_group" "vpc_endpoint_sg" { # bedoelt om de vpn server toegang te geven tot de aws api zonder dat het verkeer over het internet gaat.
  name   = "vpn-ec2-endpoint-sg"
  vpc_id = aws_vpc.vpc_innovatech_solutions.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.vpn_sg.id] # dus alleen de vpn server mag via deze security group naar de aws api endpoint
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "vpc_endpoint" {
  vpc_id              = aws_vpc.vpc_innovatech_solutions.id
  service_name        = "com.amazonaws.eu-central-1.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.VPN_subnet.id] # we will place the endpoint in the VPN subnet so that the VPN server can use the aws api without going through the internet
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id] 
  private_dns_enabled = true
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

resource "aws_subnet" "internal_DNS_subnet1" {
  vpc_id            = aws_vpc.vpc_innovatech_solutions.id
  cidr_block        = "10.0.9.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Project = "innovatech_solutions"
    Name    = "internal_DNS_subnet1"
  }
}

resource "aws_subnet" "internal_DNS_subnet2" {
  vpc_id            = aws_vpc.vpc_innovatech_solutions.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Project = "innovatech_solutions"
    Name    = "internal_DNS_subnet2"
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

resource "aws_route_table_association" "internal_DNS_subnet1_association" {
  subnet_id      = aws_subnet.internal_DNS_subnet1.id
  route_table_id = aws_route_table.isolated_route.id
}

resource "aws_route_table_association" "internal_DNS_subnet2_association" {
  subnet_id      = aws_subnet.internal_DNS_subnet2.id
  route_table_id = aws_route_table.isolated_route.id
}


# Internal DNS -------------------------------------------------------------------------------------------
resource "aws_security_group" "resolver_endpoint_sg" {
  name        = "resolver-endpoint-sg"
  description = "Allow DNS queries from on-premises networks"
  vpc_id      = aws_vpc.vpc_innovatech_solutions.id

  ingress {
    description = "DNS over UDP from on-premises"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24", "10.0.0.0/16"]
  }

  ingress {
    description = "DNS over TCP from on-premises"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24", "10.0.0.0/16"] # eigenlijk werkt 192 niet want verkeer gaat van on premise krijgt nieuwe ip door masquarade door vpn.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "innovatech_solutions"
    Name    = "resolver_endpoint_sg"
  }
}

resource "aws_route53_zone" "internal_dns_zone" {
  name = "innovatech.internal"

  vpc {
    vpc_id = aws_vpc.vpc_innovatech_solutions.id
  }

  # Private DNS zone for Innovatech internal services

  tags = {
    Project = "innovatech_solutions"
    Name    = "innovatech.internal"
  }
}

resource "aws_route53_resolver_endpoint" "resolver_inbound_endpoint" {
  name               = "innovatech-inbound-resolver"
  direction          = "INBOUND"
  security_group_ids = [aws_security_group.resolver_endpoint_sg.id]

  ip_address {
    subnet_id = aws_subnet.internal_DNS_subnet1.id
    ip        = "10.0.9.10"
  }

  ip_address {
    subnet_id = aws_subnet.internal_DNS_subnet2.id
    ip        = "10.0.10.10"
  }

  tags = {
    Project = "innovatech_solutions"
    Name    = "innovatech-inbound-resolver"
  }
}


resource "aws_route53_record" "mysql_record" {
  zone_id = aws_route53_zone.internal_dns_zone.zone_id
  name    = "mysql"
  type    = "CNAME" # CNAME omdat de database een dynamisch IP heeft en we de DNS naam van de database willen gebruiken. CNAME is eigenlijk een domein naam van een domein naam.
  ttl     = 60
  records = [aws_db_instance.mysql.address]
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

  ingress {
    from_port = 9100
    to_port = 9100
    protocol = "tcp"
    cidr_blocks = ["10.0.3.0/24"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.4.0/24"]
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
  egress { # outbound traffic van database mag overal naar toe gaan
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "innovatech_solutions"
    Name    = "database_sg"
  }
}

resource "aws_security_group" "vpn_sg" {
  vpc_id = aws_vpc.vpc_innovatech_solutions.id

ingress {
    description = "WireGuard tunnel from pfSense"
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { # tijdelijke ssh toegang voor onderhoud
  description = "SSH temporary"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/24"]
}

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["10.0.3.0/24"]
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

  egress {
  description = "Temporary internet access for installation"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
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

  ingress { # zodat ik via de VPN server kan inloggen op de monitoring server voor onderhoud als dat nodig is
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["192.168.1.0/24", "10.0.4.0/24"]
  }

  ingress {
    from_port = 514
    to_port = 514
    protocol = "tcp"
    cidr_blocks = ["192.168.1.0/24", "10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"] # logs from webservers, vpn server and on premise environment
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

resource "aws_security_group" "soar_sg" {
  vpc_id = aws_vpc.vpc_innovatech_solutions.id

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["10.0.3.0/24"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.3.0/24"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.3.0/24"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.3.0/24"]
  }

    ingress { # ssh for central updates (ansible)
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["192.168.1.0/24", "10.0.4.0/24"]
  }

  egress { # zodat de SOAR server overal naar toe kan gaan voor updates en API calls
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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

health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
  
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
  instance_type = "t3.micro" # t3.micro free tier. We can always expand ec2 during expansion.
  key_name = aws_key_pair.vpn_key.key_name

  block_device_mappings {
      device_name = "/dev/xvda" # Dit is de standaard naam voor de root-schijf
      ebs {
        volume_size = 8
        volume_type = "gp2"
      }
  }

  monitoring {
  enabled = true
}

  network_interfaces {
    associate_public_ip_address = false 
    security_groups             = [aws_security_group.webserver_SG.id]
  }
  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_instance_profile.arn
  }

# Deze script installeert Docker na deployment.
  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y docker awscli
              systemctl enable docker
              systemctl start docker

              DB_PASSWORD=$(aws ssm get-parameter \
                --name /innovatech/db/password \
                --with-decryption \
                --query Parameter.Value \
                --output text)
              
              # Inloggen op ECR
              aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin ${split("/", aws_ecr_repository.container_registry.repository_url)[0]}
              
              # De nieuwste container pullen
              docker pull ${aws_ecr_repository.container_registry.repository_url}:latest
              
              # De container correct starten MET alle variabelen op de juiste plek
              docker run -d \
                -p 80:80 \
                --name mijn-web-app \
                --restart always \
                -e DB_HOST="${aws_db_instance.mysql.address}" \
                -e DB_USER="admin" \
                -e DB_PASSWORD="$DB_PASSWORD" \
                -e DB_NAME="innovatech" \
                ${aws_ecr_repository.container_registry.repository_url}:latest

              # node exporter prometheus installeren
              dnf install -y wget

              cd /tmp
              wget https://github.com/prometheus/node_exporter/releases/download/v1.9.1/node_exporter-1.9.1.linux-amd64.tar.gz
              tar -xzf node_exporter-1.9.1.linux-amd64.tar.gz
              mv node_exporter-1.9.1.linux-amd64/node_exporter /usr/local/bin/node_exporter

              cat <<'NODEEXPORTER' > /etc/systemd/system/node_exporter.service
              [Unit]
              Description=Prometheus Node Exporter
              After=network.target

              [Service]
              ExecStart=/usr/local/bin/node_exporter
              Restart=always

              [Install]
              WantedBy=multi-user.target
              NODEEXPORTER

              systemctl daemon-reload
              systemctl enable --now node_exporter
              EOF
  )
  
tag_specifications {
  resource_type = "instance"

  tags = {
    Project = "innovatech_solutions"
    Name    = "webserver"
    Role    = "webserver"
  }
}
}


resource "aws_autoscaling_group" "webserver_asg" {
  name                = "webserver-asg"
  vpc_zone_identifier = [aws_subnet.Webserver_subnet1.id, aws_subnet.Webserver_subnet2.id]
  desired_capacity    = 2
  max_size            = 3
  min_size            = 2
  force_delete        = true # kijkt niet of er eerst running instances zijn, maar verwijdert ze direct

  target_group_arns   = [aws_lb_target_group.alb_webserver_tg.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 420

  launch_template { # hier vertellen we de autoscaler welke launch template hij moet gebruiken
    id      = aws_launch_template.template_ec2.id
    version = "$Latest"
  }
}

# Een container registry waar ik mijn image in opsla.
resource "aws_ecr_repository" "container_registry" {
  name                 = "container_registry"
}

resource "aws_ecr_repository" "soar_container_registry" {
  name                 = "soar_container_registry"
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
    },
    {
      "Action": [
        "ssm:GetParameter"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:ssm:eu-central-1:${data.aws_caller_identity.current.account_id}:parameter/innovatech/db/password"
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
resource "aws_s3_bucket" "loki_log_bucket" {
  bucket = "loki-log-bucket-2026" # unieke naam voor de bucket
}

resource "aws_autoscaling_group" "monitoring_asg" {
  name                = "monitoring-asg"
  vpc_zone_identifier = [aws_subnet.Monitoring_subnet.id]
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  force_delete        = true # kijkt niet of er eerst running instances zijn, maar verwijdert ze direct

  health_check_type         = "EC2"
  health_check_grace_period = 420

  launch_template { # hier vertellen we de autoscaler welke launch template hij moet gebruiken
    id      = aws_launch_template.monitoring_ec2.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "monitoring_ec2" {
  name_prefix   = "monitoring_ec2-"
  image_id      = data.aws_ssm_parameter.ec2_ami.value
  instance_type = "t3.micro" # t3.micro free tier. We can always expand ec2 during expansion.
  key_name = aws_key_pair.vpn_key.key_name
  update_default_version = true

  iam_instance_profile {
    arn = aws_iam_instance_profile.prometheus_ec2_instance_profile.arn
  }

  block_device_mappings {
      device_name = "/dev/xvda" # Dit is de standaard naam voor de root-schijf
      ebs {
        volume_size = 8
        volume_type = "gp2"
      }
  }
      user_data = base64encode(<<-EOF
                #!/bin/bash
                dnf update -y
                dnf install -y docker git awscli
                systemctl enable docker
                systemctl start docker

                mkdir -p /usr/local/lib/docker/cli-plugins
                curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
                chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

                git clone https://github.com/I562291/Innovatech-Solutions.git /opt/innovatech
                cd /opt/innovatech/monitoring
                DISCORD_WEBHOOK_URL=$(aws ssm get-parameter \
                  --name /innovatech/discord/webhook \
                  --with-decryption \
                  --query Parameter.Value \
                  --output text)
                printf 'DISCORD_WEBHOOK_URL=%s\n' "$DISCORD_WEBHOOK_URL" > .env
                chmod 600 .env

                cat > /etc/systemd/system/monitoring-stack.service <<'SERVICE'
                [Unit]
                Description=Innovatech monitoring Docker Compose stack
                Requires=docker.service
                After=docker.service

                [Service]
                Type=simple
                WorkingDirectory=/opt/innovatech/monitoring
                ExecStart=/usr/local/lib/docker/cli-plugins/docker-compose up
                ExecStop=/usr/local/lib/docker/cli-plugins/docker-compose stop
                Restart=always
                RestartSec=10

                [Install]
                WantedBy=multi-user.target
                SERVICE

                systemctl daemon-reload
                systemctl enable --now monitoring-stack.service

                TOKEN=$(curl -sS -X PUT http://169.254.169.254/latest/api/token \
                  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
                PRIVATE_IP=$(curl -sS \
                  -H "X-aws-ec2-metadata-token: $TOKEN" \
                  http://169.254.169.254/latest/meta-data/local-ipv4)
                cat > /tmp/grafana-dns-change.json <<DNS
                {
                  "Comment": "Update Grafana record to the current monitoring instance",
                  "Changes": [{
                    "Action": "UPSERT",
                    "ResourceRecordSet": {
                      "Name": "grafana.innovatech.internal",
                      "Type": "A",
                      "TTL": 60,
                      "ResourceRecords": [{"Value": "$PRIVATE_IP"}]
                    }
                  }]
                }
                DNS
                aws route53 change-resource-record-sets \
                  --hosted-zone-id ${aws_route53_zone.internal_dns_zone.zone_id} \
                  --change-batch file:///tmp/grafana-dns-change.json \
                  --region eu-central-1
                EOF
  )

  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
        Name    = "Monitoring Server"
        Project = "innovatech_solutions"
    }
  }
}


resource "aws_iam_role" "prometheus_role" {
  name = "prometheus-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = "innovatech_solutions"
  }
}

resource "aws_iam_policy" "prometheus_policy" {
  name        = "prometheus-policy"
  description = "Allows Prometheus EC2 service discovery to read EC2 tags and instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = "arn:aws:ssm:eu-central-1:${data.aws_caller_identity.current.account_id}:parameter/innovatech/discord/webhook"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = aws_route53_zone.internal_dns_zone.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "prometheus_role_policy_attachment" {
  role       = aws_iam_role.prometheus_role.name
  policy_arn = aws_iam_policy.prometheus_policy.arn
}

resource "aws_iam_instance_profile" "prometheus_ec2_instance_profile" {
  name = "prometheus-ec2-instance-profile"
  role = aws_iam_role.prometheus_role.name
}

# vpn server ----------------------------------------------------------------------------------------------
resource "aws_autoscaling_group" "vpn_asg" {
  name                = "vpn-asg"
  vpc_zone_identifier = [aws_subnet.VPN_subnet.id]
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  force_delete        = true
  depends_on = [aws_vpc_endpoint.vpc_endpoint]

  health_check_type         = "EC2"
  health_check_grace_period = 420

  launch_template {
    id      = aws_launch_template.vpn_ec2.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "vpn_ec2" {
  name_prefix   = "vpn_ec2-"
  image_id      = data.aws_ssm_parameter.ec2_ami.value
  instance_type = "t3.micro"
  key_name      = aws_key_pair.vpn_key.key_name
  update_default_version = true

  iam_instance_profile {
    arn = aws_iam_instance_profile.vpn_ssm_instance_profile.arn
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.vpn_sg.id]
    delete_on_termination       = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 8
      volume_type = "gp2"
    }
  }

  user_data = base64encode(<<-EOF
                #!/bin/bash
                TOKEN=$(curl -sS -X PUT http://169.254.169.254/latest/api/token \
                  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
                INSTANCE_ID=$(curl -sS \
                  -H "X-aws-ec2-metadata-token: $TOKEN" \
                  http://169.254.169.254/latest/meta-data/instance-id)
                aws ec2 modify-instance-attribute \
                  --instance-id "$INSTANCE_ID" \
                  --no-source-dest-check \
                  --region eu-central-1
                aws ec2 associate-address \
                  --instance-id "$INSTANCE_ID" \
                  --allocation-id ${data.aws_eip.vpn_static_ip.id} \
                  --allow-reassociation \
                  --region eu-central-1

                # Wacht tot Elastic IP geassocieerd is en internet werkt
                until ping -c 1 8.8.8.8 &>/dev/null; do
                    sleep 3
                done
                # 1. install wireguard-tools
                dnf update -y
                dnf install wireguard-tools iptables awscli -y 

                WIREGUARD_PRIVATE_KEY=$(aws ssm get-parameter \
                  --name /innovatech/wireguard/private-key \
                  --with-decryption \
                  --query Parameter.Value \
                  --output text)

                # 2. enable IP forwarding
                echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-wireguard.conf
                sysctl -p /etc/sysctl.d/99-wireguard.conf

                # 3. configure wireguard
                mkdir -p /etc/wireguard
                cat << CONFIG > /etc/wireguard/wg0.conf
                [Interface]
                PrivateKey = $${WIREGUARD_PRIVATE_KEY}
                Address = 10.10.4.2/32
                ListenPort = 51820

                PostUp = iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
                PostDown = iptables -t nat -D POSTROUTING -o ens5 -j MASQUERADE

                [Peer]
                PublicKey = UFZhBD13qwfvpbUGsFKFW9Q9Z1jyEUnkXlO0DNAjmic=
                AllowedIPs = 10.10.4.1/32, 192.168.1.0/24
                CONFIG

                chmod 600 /etc/wireguard/wg0.conf
                mkdir -p /etc/systemd/system/wg-quick@wg0.service.d
                cat <<'RESTART' > /etc/systemd/system/wg-quick@wg0.service.d/restart.conf
                [Service]
                Restart=on-failure
                RestartSec=10
                RESTART
                systemctl enable --now wg-quick@wg0

                TOKEN=$(curl -sS -X PUT http://169.254.169.254/latest/api/token \
                  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
                PRIVATE_IP=$(curl -sS \
                  -H "X-aws-ec2-metadata-token: $TOKEN" \
                  http://169.254.169.254/latest/meta-data/local-ipv4)
                cat > /tmp/vpn-dns-change.json <<DNS
                {
                  "Comment": "Update VPN record to the current VPN instance",
                  "Changes": [{
                    "Action": "UPSERT",
                    "ResourceRecordSet": {
                      "Name": "vpn.innovatech.internal",
                      "Type": "A",
                      "TTL": 60,
                      "ResourceRecords": [{"Value": "$PRIVATE_IP"}]
                    }
                  }]
                }
                DNS
                aws route53 change-resource-record-sets \
                  --hosted-zone-id ${aws_route53_zone.internal_dns_zone.zone_id} \
                  --change-batch file:///tmp/vpn-dns-change.json \
                  --region eu-central-1

                # node exporter prometheus installeren
                dnf install -y wget

                cd /tmp
                wget https://github.com/prometheus/node_exporter/releases/download/v1.9.1/node_exporter-1.9.1.linux-amd64.tar.gz
                tar -xzf node_exporter-1.9.1.linux-amd64.tar.gz
                mv node_exporter-1.9.1.linux-amd64/node_exporter /usr/local/bin/node_exporter

                cat <<'NODEEXPORTER' > /etc/systemd/system/node_exporter.service
                [Unit]
                Description=Prometheus Node Exporter
                After=network.target

                [Service]
                ExecStart=/usr/local/bin/node_exporter
                Restart=always

                [Install]
                WantedBy=multi-user.target
                NODEEXPORTER

                systemctl daemon-reload
                systemctl enable --now node_exporter
                EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Project = "innovatech_solutions"
      Name    = "VPN Server"
      Role    = "vpn"
    }
  }
}

# soar system ----------------------------------------------------------------------------------------------
resource "aws_autoscaling_group" "soar_asg" {
  name                = "soar-asg"
  vpc_zone_identifier = [aws_subnet.Monitoring_subnet.id]
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  force_delete        = true

  health_check_type         = "EC2"
  health_check_grace_period = 420

  launch_template {
    id      = aws_launch_template.soar_ec2.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "soar_ec2" {
  name_prefix   = "soar_ec2-"
  image_id      = data.aws_ssm_parameter.ec2_ami.value
  instance_type = "t3.micro"
  key_name      = aws_key_pair.vpn_key.key_name
  update_default_version = true

  iam_instance_profile {
    arn = aws_iam_instance_profile.soar_instance_profile.arn
  }

  vpc_security_group_ids = [aws_security_group.soar_sg.id]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 8
      volume_type = "gp2"
    }
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    dnf update -y
    dnf install -y docker awscli curl
    systemctl enable --now docker

    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com"
    aws ecr get-login-password --region eu-central-1 \
      | docker login --username AWS --password-stdin "$ECR_REGISTRY"
    docker pull "$ECR_REGISTRY/soar_container_registry:latest"

    TOKEN=$(curl -sS -X PUT http://169.254.169.254/latest/api/token \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    PRIVATE_IP=$(curl -sS \
      -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/local-ipv4)
    cat > /tmp/soar-dns-change.json <<DNS
    {
      "Comment": "Update SOAR record to the current SOAR instance",
      "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "soar.innovatech.internal",
          "Type": "A",
          "TTL": 60,
          "ResourceRecords": [{"Value": "$PRIVATE_IP"}]
        }
      }]
    }
    DNS
    aws route53 change-resource-record-sets \
      --hosted-zone-id ${aws_route53_zone.internal_dns_zone.zone_id} \
      --change-batch file:///tmp/soar-dns-change.json \
      --region eu-central-1

    dnf install -y wget
    cd /tmp
    wget https://github.com/prometheus/node_exporter/releases/download/v1.9.1/node_exporter-1.9.1.linux-amd64.tar.gz
    tar -xzf node_exporter-1.9.1.linux-amd64.tar.gz
    mv node_exporter-1.9.1.linux-amd64/node_exporter /usr/local/bin/node_exporter

    cat > /etc/systemd/system/node_exporter.service <<'NODEEXPORTER'
    [Unit]
    Description=Prometheus Node Exporter
    After=network.target

    [Service]
    ExecStart=/usr/local/bin/node_exporter
    Restart=always

    [Install]
    WantedBy=multi-user.target
    NODEEXPORTER

    systemctl daemon-reload
    systemctl enable --now node_exporter

    cat > /etc/systemd/system/soar.service <<SERVICE
    [Unit]
    Description=Innovatech SOAR
    After=docker.service
    Requires=docker.service

    [Service]
    Type=simple
    ExecStart=/usr/bin/docker run --name soar --rm --init -p 8080:8080 --restart=no "$ECR_REGISTRY/soar_container_registry:latest"
    ExecStop=/usr/bin/docker stop soar
    Restart=always
    RestartSec=10

    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable --now soar.service
    EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Project = "innovatech_solutions"
      Name    = "SOAR Server"
      Role    = "soar"
    }
  }
}

resource "aws_iam_role" "soar_role" {
  name = "soar-role"

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

resource "aws_iam_policy" "soar_policy" {
  name = "soar-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets"]
        Resource = aws_route53_zone.internal_dns_zone.arn
      },
      {
        Effect = "Allow" # dit is nodig zodat de SOAR server de container kan pullen uit de ECR registry
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = [
          aws_ecr_repository.soar_container_registry.arn,
          "*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = "arn:aws:ssm:eu-central-1:${data.aws_caller_identity.current.account_id}:parameter/innovatech/discord/webhook" # hiermee kan de soar server de discord webhook ophalen uit de parameter store
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "soar_policy_attachment" {
  role       = aws_iam_role.soar_role.name
  policy_arn = aws_iam_policy.soar_policy.arn
}

resource "aws_iam_instance_profile" "soar_instance_profile" {
  name = "soar-instance-profile"
  role = aws_iam_role.soar_role.name
}

data "aws_eip" "vpn_static_ip" {
  tags = {
    Name = "vpn_static_ip"
  }
}

resource "aws_key_pair" "vpn_key" {
  key_name   = "innovatech-vpn"
  public_key = file("~/.ssh/innovatech-vpn.pub")
}

resource "aws_iam_role" "vpn_ssm_role" { # bedoelt om de vpn server toegang te geven tot de ssm parameter store zodat hij de private key kan ophalen
  name = "vpn-ssm-role"

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

resource "aws_iam_policy" "vpn_ssm_policy" {
  name = "vpn-ssm-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssm:GetParameter"
      ]
      Resource = "arn:aws:ssm:eu-central-1:${data.aws_caller_identity.current.account_id}:parameter/innovatech/wireguard/private-key"
    }, {
      Effect = "Allow"
      Action = [
        "route53:ChangeResourceRecordSets"
      ]
      Resource = aws_route53_zone.internal_dns_zone.arn
    }, {
      Effect = "Allow"
      Action = [ # bedoelt om de vpn server een elastic ip te geven zodat hij altijd hetzelfde ip heeft
        "ec2:AssociateAddress",
        "ec2:ModifyInstanceAttribute",
        "ec2:DescribeInstances"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "vpn_ssm_policy_attachment" {
  role       = aws_iam_role.vpn_ssm_role.name
  policy_arn = aws_iam_policy.vpn_ssm_policy.arn
}

resource "aws_iam_instance_profile" "vpn_ssm_instance_profile" {
  name = "vpn-ssm-instance-profile"
  role = aws_iam_role.vpn_ssm_role.name
}

# mysql database ----------------------------------------------------------------------------------------------
resource "aws_db_instance" "mysql" {
  identifier        = "mysql-instance"
  engine            = "mysql"
  engine_version    = "8.4"
  allow_major_version_upgrade = true
  instance_class    = "db.t3.micro"
  storage_type      = "gp2"
  allocated_storage = 20
  username          = "admin"
  password          = data.aws_ssm_parameter.db_password.value
  db_name           = "innovatech"
  skip_final_snapshot = true # zodat als ik terraform destroy/delete doe dat echt alles weg is, in productie is dit natuurlijk niet slim
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  db_subnet_group_name = aws_db_subnet_group.mysql_subnet_group.name
  publicly_accessible = false
  backup_retention_period = 7   # Kiest hoe lang de backups bewaard blijven (bijv. 7 dagen)
  backup_window           = "03:00-04:00" # Tijdstip in de nacht waarop de daily snapshot wordt gemaakt

  tags = {
    Name    = "mysql"
    Project = "innovatech_solutions"
  }
}

resource "aws_db_subnet_group" "mysql_subnet_group" {
  name       = "mysql-subnet-group"
  subnet_ids = [aws_subnet.Database_subnet1.id, aws_subnet.Database_subnet2.id]
}