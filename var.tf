# AWS Provider Variables
variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ca-central-1"
}

# VPC Variables
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_1" {
  description = "CIDR block for the first public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr_2" {
  description = "CIDR block for the second public subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "availability_zone_1" {
  description = "First availability zone for subnets"
  type        = string
  default     = "ca-central-1a"
}

variable "availability_zone_2" {
  description = "Second availability zone for subnets"
  type        = string
  default     = "ca-central-1b"
}

# SSH Key File Variables
variable "bastion_private_key_filename" {
  description = "Filename for the bastion private key"
  type        = string
  default     = "bastion_key.pem"
}

variable "ec2_private_key_filename" {
  description = "Filename for the EC2 private key"
  type        = string
  default     = "ec2_key.pem"
}

variable "bastion_sg_config" {
  description = "Configuration for the bastion security group"
  type = object({
    name = string
    ingress_rules = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
    egress_rules = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
    tags = map(string)
  })
  default = {
    name = "bastion-sg"
    ingress_rules = [
      {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Restrict in production
      }
    ]
    egress_rules = [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
    tags = {
      Name = "bastion-sg"
    }
  }
}
variable "allowed_ingress_ports" {
  description = "List of ports to allow in ingress rules (if provided, overrides bastion_sg_config.ingress_rules)"
  type        = list(number)
  default     = [] # Empty list means use bastion_sg_config.ingress_rules
}

variable "allowed_egress_ports" {
  description = "List of ports to allow in egress rules (if provided, overrides bastion_sg_config.egress_rules)"
  type        = list(number)
  default     = [] # Empty list means use bastion_sg_config.egress_rules
}