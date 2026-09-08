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

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/24"
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "HUB"
  }
}