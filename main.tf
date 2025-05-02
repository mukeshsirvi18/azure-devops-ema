terraform {
  backend "s3" {
    bucket         = "mukesh-s3-backend"
    key            = "terraform.tfstate"
    region         = "ca-central-1"
  }
}
provider "aws" {
  region = var.aws_region
}

# Generate SSH key pair for the bastion host
resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store the bastion private key locally
resource "local_file" "bastion_private_key" {
  content         = tls_private_key.bastion_key.private_key_pem
  filename        = "${path.module}/${var.bastion_private_key_filename}"
  file_permission = "0600"
}

# Generate SSH key pair for the EC2 instance
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store the EC2 private key locally
resource "local_file" "ec2_private_key" {
  content         = tls_private_key.ec2_key.private_key_pem
  filename        = "${path.module}/${var.ec2_private_key_filename}"
  file_permission = "0600"
}

# VPC configuration
module "vpc" {
  source = "./module/vpc"

  # Input variables for VPC
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr_1 = var.public_subnet_cidr_1
  public_subnet_cidr_2 = var.public_subnet_cidr_2
  private_subnet_cidr  = var.private_subnet_cidr
  availability_zone_1  = var.availability_zone_1
  availability_zone_2  = var.availability_zone_2
}

# Bastion host configuration
module "bastion" {
  source = "./module/bastion"

  # Pass dependencies from VPC and SSH keys
  vpc_id             = module.vpc.vpc_id
  public_subnet_id   = module.vpc.public_subnet_id_1
  bastion_public_key = tls_private_key.bastion_key.public_key_openssh
  ec2_private_key    = tls_private_key.ec2_key.private_key_pem
  bastion_sg_config  = var.bastion_sg_config
  allowed_ingress_ports = var.allowed_ingress_ports
  allowed_egress_ports  = var.allowed_egress_ports
}

# EC2 configuration (3-tier application)
module "ec2" {
  source = "./module/ec2"

  # Pass dependencies from VPC, Bastion, and SSH keys
  vpc_id                    = module.vpc.vpc_id
  private_subnet_id         = module.vpc.private_subnet_id
  alb_security_group_id     = module.alb.alb_security_group_id
  bastion_security_group_id = module.bastion.bastion_security_group_id
  ec2_public_key            = tls_private_key.ec2_key.public_key_openssh
}

# ALB configuration
module "alb" {
  source = "./module/alb"

  # Pass dependencies from VPC and EC2
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = [module.vpc.public_subnet_id_1, module.vpc.public_subnet_id_2]
  ec2_instance_id   = module.ec2.ec2_instance_id
}
