# =====================================================
# VPC Outputs
# =====================================================

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

# =====================================================
# EC2 Instance Outputs
# =====================================================

output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = module.nginx_ec2_instance.id
}

output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = module.nginx_ec2_instance.public_ip
}

output "instance_private_ip" {
  description = "The private IP address of the EC2 instance"
  value       = module.nginx_ec2_instance.private_ip
}

output "instance_arn" {
  description = "The ARN of the EC2 instance"
  value       = module.nginx_ec2_instance.arn
}

output "security_group_id" {
  description = "The ID of the security group created for the instance"
  value       = module.nginx_ec2_instance.security_group_id
}

output "nginx_url" {
  description = "URL to access Nginx web server"
  value       = "http://${module.nginx_ec2_instance.public_ip}"
}
