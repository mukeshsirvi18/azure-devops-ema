# bastion/bastion.tf
# Configures a bastion host in the public subnet for SSH access to private instances

# Input variables


# Create a security group for the bastion host
resource "aws_security_group" "bastion_sg" {
  vpc_id = var.vpc_id
  name   = var.bastion_sg_config["name"]

# In aws_security_group.bastion_sg, replace the dynamic ingress and egress blocks with:

# Ingress rules from allowed_ingress_ports (if non-empty)
dynamic "ingress" {
  for_each = length(var.allowed_ingress_ports) > 0 ? toset(var.allowed_ingress_ports) : []
  iterator = port
  content {
    from_port   = port.value
    to_port     = port.value
    protocol    = "tcp"
    cidr_blocks = length(var.bastion_sg_config["ingress_rules"]) > 0 ? var.bastion_sg_config["ingress_rules"][0].cidr_blocks : ["0.0.0.0/0"]
  }
}

# Ingress rules from bastion_sg_config.ingress_rules (if allowed_ingress_ports is empty)
dynamic "ingress" {
  for_each = length(var.allowed_ingress_ports) == 0 ? var.bastion_sg_config["ingress_rules"] : []
  iterator = rule
  content {
    from_port   = rule.value.from_port
    to_port     = rule.value.to_port
    protocol    = rule.value.protocol
    cidr_blocks = rule.value.cidr_blocks
  }
}

# Egress rules from allowed_egress_ports (if non-empty)
dynamic "egress" {
  for_each = length(var.allowed_egress_ports) > 0 ? toset(var.allowed_egress_ports) : []
  iterator = port
  content {
    from_port   = port.value
    to_port     = port.value
    protocol    = "tcp"
    cidr_blocks = length(var.bastion_sg_config["egress_rules"]) > 0 ? var.bastion_sg_config["egress_rules"][0].cidr_blocks : ["0.0.0.0/0"]
  }
}

# Egress rules from bastion_sg_config.egress_rules (if allowed_egress_ports is empty)
dynamic "egress" {
  for_each = length(var.allowed_egress_ports) == 0 ? var.bastion_sg_config["egress_rules"] : []
  iterator = rule
  content {
    from_port   = rule.value.from_port
    to_port     = rule.value.to_port
    protocol    = rule.value.protocol
    cidr_blocks = rule.value.cidr_blocks
  }
}
  tags = var.bastion_sg_config["tags"]
}

# Create a key pair for the bastion host
resource "aws_key_pair" "bastion_key" {
  key_name   = "bastion-key"
  public_key = var.bastion_public_key
}

# Create the bastion host EC2 instance
resource "aws_instance" "bastion" {
  ami                    = "ami-08355844f8bc94f55"  
  instance_type          = "t2.micro"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = aws_key_pair.bastion_key.key_name

  # User data to configure the EC2 instance's private key on the bastion
  user_data = <<-EOF
              #!/bin/bash
              # Create .ssh directory for ubuntu user
              sudo mkdir -p /home/ubuntu/.ssh
              
              # Store the EC2 private key securely
              echo "${var.ec2_private_key}" | sudo tee /home/ubuntu/.ssh/ec2_key.pem > /dev/null
              
              # Set correct ownership and permissions
              sudo chown ubuntu:ubuntu /home/ubuntu/.ssh/ec2_key.pem
              sudo chmod 600 /home/ubuntu/.ssh/ec2_key.pem
              EOF

  tags = {
    Name = "bastion-host"
  }
}

# Output the bastion host public IP
output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.bastion.public_ip
}

# Output the bastion security group ID
output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion_sg.id
}