# alb/alb.tf
# Configures Application Load Balancer, target group, and listener in public subnets

# Input variables
# Create a security group for the ALB
resource "aws_security_group" "alb_sg" {
  vpc_id = var.vpc_id
  name   = "alb-sg"

  # Allow HTTP inbound from anywhere
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

# Create an Application Load Balancer
resource "aws_lb" "main_alb" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids # Use list of public subnets

  tags = {
    Name = "main-alb"
  }
}

# Create a target group for the ALB
resource "aws_lb_target_group" "main_tg" {
  name     = "main-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "main-tg"
  }
}

# Register the EC2 instance with the target group
resource "aws_lb_target_group_attachment" "main_tg_attachment" {
  target_group_arn = aws_lb_target_group.main_tg.arn
  target_id        = var.ec2_instance_id
  port             = 5000
}

# Create a listener for the ALB
resource "aws_lb_listener" "main_listener" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main_tg.arn
  }
}

# Output the ALB DNS name
output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.main_alb.dns_name
}

# Output the ALB security group ID
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb_sg.id
}