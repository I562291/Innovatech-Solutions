# AWS IaC scaffold

This folder is prepared for an AWS infrastructure-as-code implementation with a hub-spoke topology:

- `modules/hub-gateway`: hub VPC/network gateway resources
- `modules/spoke-network`: spoke VPC/subnets (public web subnet and private DB subnet)
- `modules/load-balancer`: load balancer resources in front of web servers
- `modules/webservers-containers`: containerized web server resources (2 instances/tasks)
- `modules/database-private`: private database resources
- `modules/security-groups`: security groups and traffic rules
- `environments/dev` and `environments/prod`: environment-specific stacks/composition
