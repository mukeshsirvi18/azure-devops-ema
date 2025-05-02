# ec2/ec2.tf
# Configures EC2 instance in private subnet with 3-tier application

# Input variables


# Create a security group for the EC2 instance
resource "aws_security_group" "ec2_sg" {
  vpc_id = var.vpc_id
  name   = "ec2-sg"

  # Allow HTTP inbound from the ALB
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  # Allow SSH inbound from the bastion host
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_security_group_id]
  }

  # Allow port 5000 inbound from anywhere
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic (for NAT Gateway access)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

# Create a key pair for the EC2 instance
resource "aws_key_pair" "ec2_key" {
  key_name   = "ec2-key"
  public_key = var.ec2_public_key
}


# Create an EC2 instance in the private subnet
resource "aws_instance" "web_server" {
  ami                    = "ami-08355844f8bc94f55" 
  instance_type          = "t2.micro"
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = aws_key_pair.ec2_key.key_name

  user_data = <<-EOF
              #!/bin/bash

              # Update package list
              sudo apt update 

              # Install Node.js LTS
              curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
              sudo apt-get install -y nodejs

              # Install Git
              sudo apt install git

              # Install MySQL
              sudo apt-get update -y
              sudo apt-get install -y mysql-server

              # Clone the Git repository with logging
              cd /home/ubuntu
              sudo git clone https://github.com/git-hub-sachin/Project-App -b master > clone_log.txt 2>&1

              # Check the log for errors if git clone fails
              if [ $? -ne 0 ]; then
                echo "Git clone failed, check clone_log.txt for errors."
                exit 1
              fi

              # Create MySQL DB, user, and table
              sudo mysql <<EOL
              CREATE DATABASE IF NOT EXISTS employees_db;
              CREATE USER IF NOT EXISTS 'archit'@'%' IDENTIFIED BY 'Password1!';
              GRANT ALL PRIVILEGES ON employees_db.* TO 'archit'@'%';
              FLUSH PRIVILEGES;

              USE employees_db;
              CREATE TABLE IF NOT EXISTS EMPLOYEES (
                 emp_id INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
                 emp_name VARCHAR(225) NOT NULL,
                 emp_contact VARCHAR(10),
                 emp_add VARCHAR(225) DEFAULT NULL
              ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
              EOL

              # Install PM2 globally
              sudo npm install -g pm2

              # Install Backend Dependencies
              cd /home/ubuntu/Project-App/backend
              sudo npm install

              # Start Backend App with PM2
              sudo pm2 start app.js --name backend-app -- -d

              # Install Frontend Dependencies
              cd /home/ubuntu/Project-App/frontend
              npm install

              # Start Frontend App with PM2
              pm2 start app.js --name frontend-app
              EOF

  tags = {
    Name = "web-server-private"
  }
}


# Output the EC2 instance ID
output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

# Output the EC2 private IP (for SSH from bastion)
output "ec2_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.web_server.private_ip
}