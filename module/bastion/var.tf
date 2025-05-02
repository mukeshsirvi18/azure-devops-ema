variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet"
  type        = string
}

variable "bastion_public_key" {
  description = "Public key for the bastion host"
  type        = string
}

variable "ec2_private_key" {
  description = "Private key for the private EC2 instance"
  type        = string
  sensitive   = true
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
        cidr_blocks = ["0.0.0.0/0"] # Restrict CIDR in production
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