output "load_balancer_url" {
  description = "The DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}
output "ec2_instance_id" {
    value = module.bastion.bastion_public_ip
}